import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { Script, createContext } from 'node:vm';

function loadLogic() {
  const source = readFileSync(new URL('../utils/desktopEntryLogic.js', import.meta.url), 'utf8');
  const context = createContext({});
  new Script(source).runInContext(context);
  return context;
}

function desktopEntriesById(entries) {
  return {
    byId(id) {
      return entries[id] || null;
    }
  };
}

{
  const logic = loadLogic();
  const vscode = { id: 'code', icon: 'visual-studio-code', command: ['/usr/bin/code'] };
  const opencode = { id: 'opencode-desktop', icon: 'opencode-desktop', command: ['opencode-desktop'] };
  const desktopEntries = desktopEntriesById({ code: vscode });
  const themeIcons = {
    findAppEntry() {
      return opencode;
    }
  };

  assert.equal(logic.findDesktopEntry(desktopEntries, themeIcons, 'code.desktop'), vscode);
}

{
  const logic = loadLogic();
  const opencode = { id: 'opencode-desktop', icon: 'opencode-desktop', command: ['opencode-desktop'] };
  const desktopEntries = desktopEntriesById({});
  const themeIcons = {
    findAppEntry() {
      return opencode;
    }
  };

  assert.equal(logic.findDesktopEntry(desktopEntries, themeIcons, 'opencode'), opencode);
}
