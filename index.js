// index.js - A simple Node.js script for pipeline testing
const os = require('os');

console.log('Hello from the Azure DevOps Pipeline!');
console.log(`Running on platform: ${os.platform()}`);
console.log(`Architecture: ${os.arch()}`);
console.log(`Total Memory (GB): ${(os.totalmem() / (1024 ** 3)).toFixed(2)}`);

// This will be checked in the pipeline to ensure the script ran successfully.
if (process.version) {
    console.log(`Node.js Version: ${process.version}`);
    process.exit(0); // Success
} else {
    console.error('ERROR: Could not find Node.js version.');
    process.exit(1); // Failure
}