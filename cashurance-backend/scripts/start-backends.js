const { spawn, spawnSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const root = path.resolve(__dirname, '..');
const pythonCwd = path.join(root, 'python');
const venvPythonBin = path.join(pythonCwd, '.venv', 'bin', 'python');
const pythonBin = process.env.PYTHON_BIN || (fs.existsSync(venvPythonBin) ? venvPythonBin : 'python3');
const mlPort = process.env.ML_PORT || '8001';
const mlHost = process.env.ML_HOST || '127.0.0.1';

if (!process.env.PYTHON_BIN && !fs.existsSync(venvPythonBin)) {
    const venvCreate = spawnSync('python3', ['-m', 'venv', '.venv'], {
        cwd: pythonCwd,
        shell: true,
        stdio: 'inherit',
    });

    if (venvCreate.status !== 0) {
        console.error('[python-ml] Failed to create Python virtual environment.');
        process.exit(venvCreate.status || 1);
    }
}

const resolvedPythonBin = process.env.PYTHON_BIN || (fs.existsSync(venvPythonBin) ? venvPythonBin : 'python3');

const pipInstall = spawnSync(
    resolvedPythonBin,
    ['-m', 'pip', 'install', '-r', 'requirements.txt'],
    {
        cwd: pythonCwd,
        shell: true,
        stdio: 'inherit',
    },
);

if (pipInstall.status !== 0) {
    console.error('[python-ml] Failed to install Python dependencies.');
    process.exit(pipInstall.status || 1);
}

function startProcess({ name, command, args, cwd }) {
    const proc = spawn(command, args, {
        cwd,
        shell: true,
        stdio: 'inherit',
    });

    proc.on('exit', (code, signal) => {
        const reason = signal ? `signal ${signal}` : `code ${code}`;
        console.log(`[${name}] exited with ${reason}`);
    });

    return proc;
}

const nodeProc = startProcess({
    name: 'node-backend',
    command: 'node',
    args: ['server.js'],
    cwd: path.join(root, 'node'),
});

const pythonProc = startProcess({
    name: 'python-ml',
    command: resolvedPythonBin,
    args: ['-m', 'uvicorn', 'main:app', '--host', mlHost, '--port', mlPort],
    cwd: pythonCwd,
});

let shuttingDown = false;

function shutdown(exitCode = 0) {
    if (shuttingDown) return;
    shuttingDown = true;

    if (!nodeProc.killed) nodeProc.kill();
    if (!pythonProc.killed) pythonProc.kill();

    setTimeout(() => process.exit(exitCode), 200);
}

nodeProc.on('exit', (code) => {
    if (!shuttingDown) shutdown(code ?? 1);
});

pythonProc.on('exit', (code) => {
    if (!shuttingDown) shutdown(code ?? 1);
});

process.on('SIGINT', () => shutdown(0));
process.on('SIGTERM', () => shutdown(0));
