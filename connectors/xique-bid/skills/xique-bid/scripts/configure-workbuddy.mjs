#!/usr/bin/env node

import fs from 'fs';
import os from 'os';
import path from 'path';

const options = parseArgs(process.argv.slice(2));
const workbuddyHome = path.resolve(requiredOption(options, 'workbuddy-home'));
const command = path.resolve(requiredOption(options, 'command'));
const packageSpec = requiredOption(options, 'package');

if (!fs.existsSync(command)) {
    fail('找不到用于启动 MCP 的 npx：' + command);
}
if (!/^@xqyz\/workbuddy-plugin-xique@\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/.test(packageSpec)) {
    fail('MCP npm 包版本格式无效：' + packageSpec);
}

fs.mkdirSync(workbuddyHome, { recursive: true });
const configFile = path.join(workbuddyHome, 'mcp.json');
const existed = fs.existsSync(configFile);
const original = existed ? fs.readFileSync(configFile, 'utf8') : '';
let config = {};

const parseableOriginal = original.replace(/^\uFEFF/, '');
if (parseableOriginal.trim()) {
    try {
        config = JSON.parse(parseableOriginal);
    } catch (error) {
        fail('WorkBuddy MCP 配置不是有效 JSON，已停止且没有修改文件：' + error.message);
    }
}
if (!isObject(config)) {
    fail('WorkBuddy MCP 配置根节点必须是 JSON 对象，已停止且没有修改文件。');
}
if (config.mcpServers === undefined) {
    config.mcpServers = {};
} else if (!isObject(config.mcpServers)) {
    fail('WorkBuddy MCP 配置中的 mcpServers 必须是 JSON 对象，已停止且没有修改文件。');
}

const previous = isObject(config.mcpServers['xique-bid'])
    ? config.mcpServers['xique-bid']
    : {};
const serverEnv = isObject(previous.env) ? { ...previous.env } : {};
const pathKey = Object.keys(serverEnv).find(key => key.toLowerCase() === 'path') || 'PATH';
const inheritedPath = String(serverEnv[pathKey] || process.env.PATH || process.env.Path || '');
const runtimeDirectory = path.dirname(command);
serverEnv[pathKey] = [
    runtimeDirectory,
    ...inheritedPath.split(path.delimiter).filter(entry => entry && entry !== runtimeDirectory),
].join(path.delimiter);
config.mcpServers['xique-bid'] = {
    ...previous,
    type: 'stdio',
    command,
    args: ['-y', `--package=${packageSpec}`, '--', 'xique-workbuddy-mcp'],
    env: serverEnv,
    timeout: 60000,
    disabled: false,
};

const next = JSON.stringify(config, null, 2) + os.EOL;
const changed = original !== next;
let backupFile = '';
if (changed) {
    if (existed) {
        backupFile = nextBackupPath(configFile);
        fs.copyFileSync(configFile, backupFile);
    }
    fs.writeFileSync(configFile, next, { encoding: 'utf8', mode: 0o600 });
}

process.stdout.write(JSON.stringify({
    ok: true,
    changed,
    configFile,
    backupFile,
    command,
    packageSpec,
}));

function parseArgs(args) {
    const result = {};
    for (let index = 0; index < args.length; index += 2) {
        const key = String(args[index] || '');
        const value = args[index + 1];
        if (!key.startsWith('--') || value === undefined) {
            fail('安装器参数无效。');
        }
        result[key.slice(2)] = String(value);
    }
    return result;
}

function requiredOption(values, key) {
    const value = String(values[key] || '').trim();
    if (!value) {
        fail('缺少安装器参数：--' + key);
    }
    return value;
}

function isObject(value) {
    return Boolean(value) && typeof value === 'object' && !Array.isArray(value);
}

function nextBackupPath(configFile) {
    const stamp = new Date().toISOString().replace(/[:.]/g, '-');
    let candidate = configFile + '.backup-' + stamp;
    let counter = 1;
    while (fs.existsSync(candidate)) {
        candidate = configFile + '.backup-' + stamp + '-' + counter;
        counter += 1;
    }
    return candidate;
}

function fail(message) {
    process.stderr.write(String(message) + os.EOL);
    process.exit(1);
}
