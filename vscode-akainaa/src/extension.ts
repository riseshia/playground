// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';

function getCoverageData(): Record<string, number[]> | null {
    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders) {return null;}

    const coverageFilePath = path.join(workspaceFolders[0].uri.fsPath, 'tmp/coverage.json');
    if (!fs.existsSync(coverageFilePath)) {return null;}

    const coverageData = JSON.parse(fs.readFileSync(coverageFilePath, 'utf8'));
    return coverageData;
}

const decorationTypes: vscode.TextEditorDecorationType[] = [1, 2, 3, 4, 5, 6, 7, 8].map(i => (
    vscode.window.createTextEditorDecorationType({
        backgroundColor: `rgba(255, 0, 0, ${i * 0.125})`,
        isWholeLine: true
    })
));

function updateDecorations() {
    console.log('updateDecorations called');
    const editor = vscode.window.activeTextEditor;
    if (!editor) {return;}

    const coverageData = getCoverageData();
    if (!coverageData) {return;}

    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders) {return null;}
    const prjDir = workspaceFolders[0].uri.fsPath;

    const filePath = editor.document.fileName;
    const filePathFromPrjDir = filePath.substring(prjDir.length + 1);
    const fileCoverage = coverageData[filePathFromPrjDir];
    if (!fileCoverage) {return;}

    let decorations: {
        decorationType: vscode.TextEditorDecorationType,
        decoration: { range: vscode.Range }[],
    }[] = [0, 1, 2, 3, 4, 5, 6, 7].map(i => ({
        decorationType: decorationTypes[i],
        decoration: [],
    }));

    const maxExecuted = Math.max(...fileCoverage, 9) + 1;

    for (let lineNumber = 0; lineNumber < fileCoverage.length; lineNumber++) {
        const count = fileCoverage[lineNumber];
        if (!count) {continue;}
        if (count === 0) {continue;}

        const opacityLevel = Math.floor(count * 8 / maxExecuted);

        const line = editor.document.lineAt(lineNumber);

        const decoration = {
            range: line.range,
        };
        decorations[opacityLevel].decoration.push(decoration);
    }

    decorations.forEach(({ decorationType, decoration }) => {
        editor.setDecorations(decorationType, decoration);
    });
}

function watchCoverageFile(context: vscode.ExtensionContext) {
    const coverageWatcher = vscode.workspace.createFileSystemWatcher('tmp/coverage.json');

    coverageWatcher.onDidChange(() => updateDecorations());
    coverageWatcher.onDidCreate(() => updateDecorations());
    coverageWatcher.onDidDelete(() => updateDecorations());

    context.subscriptions.push(coverageWatcher);
}

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {
	// Use the console to output diagnostic information (console.log) and errors (console.error)
	// This line of code will only be executed once when your extension is activated
	console.log('Congratulations, your extension "akainaa" is now active!');

	// The command has been defined in the package.json file
	// Now provide the implementation of the command with registerCommand
	// The commandId parameter must match the command field in package.json
	const disposable = vscode.commands.registerCommand('akainaa.helloWorld', () => {
		// The code you place here will be executed every time your command is executed
		// Display a message box to the user
		vscode.window.showInformationMessage('Hello World from akainaa!');
	});

	context.subscriptions.push(disposable);

    vscode.window.onDidChangeActiveTextEditor(updateDecorations, null, context.subscriptions);
    vscode.workspace.onDidChangeTextDocument(updateDecorations, null, context.subscriptions);

    if (vscode.window.activeTextEditor) {
        updateDecorations();
    }
	watchCoverageFile(context);
}

// This method is called when your extension is deactivated
export function deactivate() {}
