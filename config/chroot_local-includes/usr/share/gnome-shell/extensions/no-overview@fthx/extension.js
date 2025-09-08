/*
  No overview at start-up
  GNOME Shell 45+ extension
  Contributors: @fthx
  License: GPL v3
*/

import * as Main from 'resource:///org/gnome/shell/ui/main.js';

export default class NoOverviewExtension {
    enable() {
        Main.layoutManager.connectObject('startup-complete', () => {
            if (Main.overview.visible)
                Main.overview.hide();
            else
                Main.overview.connectObject('shown', () => {
                    Main.overview.hide();
                    Main.overview.disconnectObject(this);
                }, this);
        }, this);
    }

    disable() {
        Main.layoutManager.disconnectObject(this);
        Main.overview.disconnectObject(this);
    }
}
