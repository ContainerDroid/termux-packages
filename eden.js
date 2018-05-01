#!/usr/bin/env node
/*
 * vim: autoindent tabstop=4 shiftwidth=4 expandtab softtabstop=4 filetype=javascript
 */
"use strict";
const os = require('os');
const yargs = require('yargs');
const path = require('path');
const fs = require('fs');
const child_process = require('child_process');
const mkdirp = require('mkdirp');
const readline = require('readline');
const EventEmitter = require('events');
const util = require('util');

const outdir = path.join(__dirname, 'out');
const buildorder_script = path.join(__dirname, 'scripts', 'buildorder.py');
const build_script = path.join(__dirname, 'build-package.sh');

const argv = yargs
    .usage('Usage: $0 [options] <pkgs>')
    .option('verbose', {
        alias: 'v',
        type: 'count',
        describe: 'Verbosity level: {-v -vv}'
    })
    .option('arch', {
        alias: 'a',
        type: 'string',
        describe: 'Target architecture',
        default: 'aarch64',
        choices: [ 'aarch64', 'arm', 'i686', 'x86_64' ]
    })
    .option('jobs', {
        alias: 'j',
        type: 'number',
        describe: 'Number of build jobs',
        default: os.cpus().length,
        nargs: 1
    })
    .help('help')
    .alias('h', 'help')
    .alias('V', 'version')
    .argv;

function WARN()  { argv.verbose >= 0 && console.log.apply(console, arguments); }
function INFO()  { argv.verbose >= 1 && console.log.apply(console, arguments); }
function DEBUG() { argv.verbose >= 2 && console.log.apply(console, arguments); }

/* Will throw exception if buildorder.py fails */
function get_pkg_deps(pkgs) {
    pkgs = Array.isArray(pkgs) ? pkgs : [ pkgs ];
    return new Promise((resolve, reject) => {
        let deps = '';
        const script = child_process.spawn(buildorder_script, pkgs);
        script.stdout.on('data', (data) => {
            deps += data;
        });
        script.on('close', (code) => {
            if (code) {
                WARN('%s returned exit code %s for "%s"',
                     buildorder_script, code, pkgs);
                return reject(code);
            } else {
                /* Remove last element, which is an empty line */
                return resolve(deps.split('\n').slice(0, -1));
            }
        });
    });
}

/* Does not throw (can be awaited without try/catch) */
function is_finished(pkg) {
    return new Promise((resolve, reject) => {
        fs.access(path.join(outdir, pkg, 'status', '10-finish'), fs.constants.F_OK, (err) => {
            if (err) {
                return resolve(false);
            } else {
                return resolve(true);
            }
        });
    });
}

/* Will throw if get_pkg_deps (and fundamentally buildorder.py) fails.
 * Does not attempt to catch and act upon the error */
async function has_satisfied_deps(pkg) {
    const deps = await get_pkg_deps(pkg);
    DEBUG("deps for " + pkg + ":");
    DEBUG(deps);
    /* Discard pkg (last element) from the deps array */
    const answers = await Promise.all(deps.slice(0, -1).map(dep => is_finished(dep)));
    return answers.reduce((acc, cur) => { return acc && cur; }, true);
}

async function get_a_job(pkg_pool) {
    if (!pkg_pool.length) {
        return null;
    }
    for (let i = 0; i < pkg_pool.length; i++) {
        let pkg = pkg_pool[i];
        DEBUG("get_a_job: Trying pkg " + pkg);
        const statusdir = path.join(outdir, pkg, 'status');
        /* Try to access statusdir.
         * If access fails, it means we can pick it up and build it.
         * If it does not fail, then skip it, because its build
         * is either in progress, or finished already.
         */
        const inProgress = await new Promise((resolve, reject) => {
            fs.access(statusdir, fs.constants.F_OK, (err) => {
                /* Could access means there is a build in progress */
                if (err) {
                    return resolve(false);
                } else {
                    return resolve(true);
                }
            });
        });
        if (inProgress) {
            DEBUG("get_a_job: skipping pkg " + pkg);
            continue;
        }
        const satisfied = await has_satisfied_deps(pkg);
        DEBUG('does ' + pkg + ' have satisfied dependencies? ' + satisfied);
        if (satisfied === false) {
            DEBUG("get_a_job: unsatisfied deps for " + pkg);
            continue;
        }
        /* pkg is ready to build. Do not hand it over until we
         * can secure its exclusive ownership by creating
         * its statusdir
         */
        return await new Promise((resolve, reject) => {
            mkdirp(statusdir, (err) => {
                if (err) {
                    if (err.code === 'EEXIST') {
                        WARN("Continuing a previous build for " + pkg);
                    } else {
                        return reject(err);
                    }
                }
                INFO("get_a_job: selected " + pkg);
                return resolve(pkg);
            });
        });
    };
    /* Bottom of the sack,
     * haven't found any package to build */
    DEBUG("resolving to null");
    return null;
}

/*
 * "this" bound to Task object
 * Task: {
 *      worker_idx: Number,
 *      pkg: String,
 *      arch: String
 * };
 */
async function build_pkg(cancel_token) {
    const statusdir = path.join(outdir, this.pkg, "status");
    this.inotify_proc = child_process.spawn('inotifywait',
                ['-m', '-e', 'close', '--format', '%f', statusdir],
                { detached: true });
    /* stdout */
    readline.createInterface({ input: this.inotify_proc.stdout })
    .on('line', (line) => {
        /* Suppress inotify events on the status directory itself */
        if (!line) return;
        if ([ "01-fetch-extract", "02-handle-hostbuild", "03-patch",
              "04-configure", "05-make", "06-install", "07-massage",
              "08-update-sysroot", "09-create-debfile", "10-finish" ]
            .includes(line) === false) {
            return;
        }
        this.emit('build-step', line);
        if (line === "10-finish") {
            this.emit('build-finished');
        }
    });
    /* stderr */
    readline.createInterface({ input: this.inotify_proc.stderr })
    .on('line', (line) => {
        if (line === "Watches established.") {
            /* Avoid race condition. Wait until inotifywait places its watches. */
            this.emit('build-can-start');
        } else if (line !== "Setting up watches.") {
            WARN("inotifywait stderr: " + line);
        }
    });
    this.inotify_proc.on('error', (err) => {
        WARN("inotifywait error: " + err);
    });
    this.inotify_proc.on('close', (code, signal) => {
        if (code) {
            this.error = new Error("inotifywait closed with error code " +
                                   code + " from signal " + signal);
            cancel_token(this);
        }
    });
    /* Worded as such in order to serialize the code. Event emitted by
     * the inotifywait process. */
    await new Promise((resolve, reject) => {
        this.on('build-can-start', () => {
            DEBUG(this.pkg + ": Build can start");
            resolve(true);
        });
    });
    INFO("Worker " + this.worker_idx + " starting build for " + this.pkg);
    this.build_proc = child_process.spawn('bash',
                [ '-x', build_script, '-a', this.arch, this.pkg ],
                { detached: true });
    this.build_in_progress = true;
    /* Redirect stdout and stderr streams to log files */
    const out_log = fs.createWriteStream(path.join(outdir, this.pkg, 'out.log'));
    const err_log = fs.createWriteStream(path.join(outdir, this.pkg, 'err.log'));
    this.build_proc.stdout.pipe(out_log);
    this.build_proc.stderr.pipe(err_log);
    this.build_proc.on('error', (err) => {
        WARN(this.pkg + " build process error: " + err);
    });
    this.build_proc.on('close', (code, signal) => {
        if (code) {
            this.error = new Error("Build process for " + this.pkg +
                                   " failed with error code " + code +
                                   " from signal " + signal);
            cancel_token(this);
        } else {
            this.emit('build-finished');
        }
    });
    this.on('build-step', (step) => {
        this.step = step;
        WARN("[1;49;49m%d (PID %d):[0;49;49m %s: step %s",
             this.worker_idx.toString().padEnd(2),
             this.build_proc.pid.toString().padEnd(4),
             this.pkg,
             this.step);
    });
    await new Promise((resolve, reject) => {
        this.on('build-finished', () => {
            resolve(true);
        });
    });
    this.build_in_progress = false;
    /* Tear down the inotify watches */
    this.inotify_proc.kill('SIGTERM');
    /* Assume that the build process is already dead, since it
     * successfully created the 10-finish file */
    INFO("Worker " + this.worker_idx + " finished build for " + this.pkg);
    return this;
}

/* Will throw if "rm -rf ${statusdir}" fails */
async function cleanup() {
    //if (!this.build_in_progress) {
        //return;
    //};
    WARN("%s: cleaning up build for %s", this.worker_idx, this.pkg);
    this.build_proc.kill('SIGTERM');
    this.inotify_proc.kill('SIGTERM');
    await new Promise((resolve, reject) => {
        const statusdir = path.join(outdir, this.pkg, 'status');
        child_process.spawn("rm", [ "-rf", statusdir ])
        .on('close', (err) => {
            if (err) {
                reject(err);
            } else {
                resolve(true);
            }
        });
    });
    if (this.step !== "00-pre-extract") {
        return;
    }
    /*
     * If extract step is not complete, there's a high chance we
     * interrupted the build while it was downloading the source tarball.
     * Don't take the risk to leave a corrupted tarball in the cache.
     */
    await new Promise((resolve, reject) => {
        const tmpdir = path.join(outdir, this.pkg, 'tmp');
        child_process.spawn("rm", [ "-rf", tmpdir ])
        .on('close', (err) => {
            if (err) {
                reject(err);
            } else {
                resolve(true);
            }
        });
    });
}

function Task(worker_idx, pkg, arch) {
    this.worker_idx = worker_idx;
    this.pkg = pkg;
    this.arch = arch;
    this.build_pkg = build_pkg.bind(this);
    this.cleanup = cleanup.bind(this);
    this.build_in_progress = false;
}
util.inherits(Task, EventEmitter);

async function fill_task_pool(task_pool, workers, pkg_pool, arch, jobs, cancel_token) {
    if (!pkg_pool.length) {
        DEBUG("empty package pool");
        return { task_pool: task_pool, workers: workers };
    }
    while (task_pool.length < jobs) {
        const indices = task_pool.map(task => task.worker_idx);
        let new_worker_idx;
        for (new_worker_idx = 0; new_worker_idx < jobs; new_worker_idx++) {
            if (!indices.includes(new_worker_idx)) {
                break;
            }
        }
        try {
            const new_pkg = await get_a_job(pkg_pool);
            if (!new_pkg) { break; }
            const task = new Task(new_worker_idx, new_pkg, arch);
            DEBUG("New task:");
            DEBUG(task);
            task_pool.push(task);
            workers.push(task.build_pkg(cancel_token));
            pkg_pool.splice(pkg_pool.indexOf(task.pkg), 1);
        } catch (reason) {
            WARN("Failed to assign new package to the task pool, reason: ", reason);
        };
    }
    DEBUG("Task pool: ", task_pool);
    return { task_pool: task_pool, workers: workers };
}

async function main(pkg_pool, arch, jobs) {
    let task_pool, workers;

    let interrupt_count = 0;
    let forced_exit_requested;
    let cancel_token;
    /* task_canceler is a promise whose role is to break the
     * Promise.race() in case of exceptional situations, such as
     * forced termination requested by the user, or exceptions
     * thrown by the worker tasks
     */
    //let task_canceler;
    const task_canceler = new Promise((resolve, reject) => {
    //task_canceler = new Promise((resolve, reject) => {
        cancel_token = reject;
        /* Set up signal handler */
        const signal_handler = function(signal) {
            WARN('Received signal %s', signal);
            interrupt_count++;
            if (interrupt_count === 1) {
                WARN("Waiting for tasks to finish. Ctrl-c again to force termination.");
            } else {
                WARN("[1;31;49mForced termination requested, exiting...[0;49;49m");
                resolve({ forced_exit_requested: true});
            }
        };
        process.on('SIGINT',  () => { signal_handler('SIGINT'); });
        process.on('SIGTERM', () => { signal_handler('SIGTERM'); });
    });
    task_canceler.then((result) => {
        forced_exit_requested = result;
    }).catch((task) => {
        WARN("[1;31;49mBuild failed for task %s.[0;49;49m View the %s file for more details.",
             task.pkg, path.join(outdir, task.pkg, 'err.log'));
        //process.exit(1);
    });

    INFO("Building the following packets:");
    INFO(pkg_pool);
    ({ task_pool, workers } = await fill_task_pool([], [], pkg_pool, arch, jobs, cancel_token));
    while (pkg_pool.length || task_pool.length) {
        if (!task_pool.length) {
            WARN("Following packages left to build: ", pkg_pool);
            WARN("But task pool is empty (no task can get a hold of a job). Exiting");
            break;
        }
        DEBUG("Workers: ", workers);
        /* Append to the workers pool a promise that resolves only when
         * (and if) forced termination is requested (two SIGTERM or SIGINT
         * signals).
         */
        //let task;
        try {
            var task = await Promise.race(workers.concat(task_canceler));
        } catch (failed_task) {
            WARN("Failed task caught: ", failed_task.pkg, failed_task.error);
            await failed_task.cleanup();
            if (!interrupt_count) {
                interrupt_count = 1;
            }
        }
        /* Act upon the forced termination signal by cleaning up
         * the running workers' space
         */
        if (task === forced_exit_requested) {
            try {
                await Promise.all(task_pool.map((task) => { return task.cleanup(); }));
            } catch (err) {
                WARN("[1;31;49mException while cleaning up: [0;49;49m", err);
            }
            return false;
        }
        WARN("Build completed for %s", task.pkg);
        workers.splice(task_pool.indexOf(task), 1);
        task_pool.splice(task_pool.indexOf(task), 1);
        if (interrupt_count === 1) {
            /* Do not refill task pool */
            continue;
        }
        ({ task_pool, workers } = await fill_task_pool(task_pool, workers, pkg_pool, arch, jobs, cancel_token));
        DEBUG("Package pool: ", pkg_pool);
    }
    return (pkg_pool.length === 0);
}

process.on('unhandledRejection', (err) => {
    WARN("Unhandled rejection: ", err);
    process.exit(1);
});

fs.mkdir(outdir, 0o755, async (err) => {
    if (err && err.code !== 'EEXIST') {
        console.log(err);
        process.exit(1);
    }
    try {
        let pkg_args = argv._.map((pkg) => {
            try {
                fs.accessSync(pkg);
            } catch (e) {
                return "packages/" + pkg;
            }
            return pkg;
        });
        let pkg_pool = await get_pkg_deps(argv);
        console.log(pkg_pool);
        const finished = await Promise.all(pkg_pool.map((pkg) => is_finished(pkg)));
        pkg_pool = pkg_pool.filter((pkg, index) => { return !finished[index]; });
        INFO(pkg_pool);
        const rc = await main(pkg_pool, argv.arch, argv.jobs);
        if (rc === true) {
            WARN("Build finished successfully");
            process.exit(0);
        } else {
            WARN("Build failed");
            process.exit(1);
        }
    } catch (err) {
        WARN("Top-level error caught: ", err);
        process.exit(1);
    }
});
