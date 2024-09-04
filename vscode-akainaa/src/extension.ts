// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import * as fs from 'fs';
import * as path from 'path';
import { text } from 'stream/consumers';

function getCoverageData(): Record<string, number[]> | null {
    const workspaceFolders = vscode.workspace.workspaceFolders;
    if (!workspaceFolders) {return null;}

    const coverageFilePath = path.join(workspaceFolders[0].uri.fsPath, 'coverage.json');
    if (!fs.existsSync(coverageFilePath)) {return null;}

    const coverageData = JSON.parse(fs.readFileSync(coverageFilePath, 'utf8'));
    return coverageData;
}

const decorationType = vscode.window.createTextEditorDecorationType({
    isWholeLine: true,
    backgroundColor: new vscode.ThemeColor("editorInlayHint.background"),
});

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

    const decorations: vscode.DecorationOptions[] = [];
    for (let lineNumber = 0; lineNumber < fileCoverage.length; lineNumber++) {
        const count = fileCoverage[lineNumber];
        let text = '';
        if (count && count > 0) {
            const paddedCount = `${count ?? ''}`.padStart(4, ' ');
            text = ` executed: ${paddedCount}`;
        }
        
        const decoration = {
            range: new vscode.Range(lineNumber, 0, lineNumber, 0),
            renderOptions: {
                after: {
                    contentText: text,
                    color: 'grey',
                }
            }
        };
        decorations.push(decoration);
    }

    editor.setDecorations(decorationType, decorations);
}

function watchCoverageFile(context: vscode.ExtensionContext) {
    const coverageWatcher = vscode.workspace.createFileSystemWatcher('**/coverage.json');

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
