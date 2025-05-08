import * as Main from 'resource:///org/gnome/shell/ui/main.js';
import GLib from 'gi://GLib';

import * as ByteArray from 'resource:///org/gnome/shell/byteArray.js';

var settings;

export default class DateExtension {

    function init() {
    }

    function overrider(lbl) {
        var now = new Date();
        let [res, out] = GLib.spawn_sync(null, ['sudo', '-n', '/usr/local/lib/tails-get-date'], null, GLib.SpawnFlags.SEARCH_PATH, null);
        if(out == null) {
            var desired = now.toLocaleString('en-US') + ' GMT';
        } else {
            desired = ByteArray.toString(out).trim();
        }

        var t = this.lbl.get_text();
        if (t != desired) {
            last = t;
            this.lbl.set_text(desired);
        }
    }


    enable() {
        this.lbl = null;
        signalHandlerID = null;
        last = "";
        var sA = Main.panel.statusArea;
        if (!sA) { sA = Main.panel._statusArea; }

        if (!sA || !sA.dateMenu) {
            print("Looks like Shell has changed where things live again; aborting.");
            return;
        }

        sA.dateMenu.first_child.get_children().forEach(function(w) {
            // assume that the text label is the first StLabel we find.
            // This is dodgy behaviour but there's no reliable way to
            // work out which it is.
            w.set_style("text-align: center;");
            if (w.get_text && !this.lbl) {
                this.lbl = w;
            }
        });
        if (!this.lbl) {
            print("Looks like Shell has changed where things live again; aborting.");
            return;
        }
        signalHandlerID = this.lbl.connect("notify::text", overrider);
        last = this.lbl.get_text();
        overrider(this.lbl);
    }

    disable() {
        if (this.lbl && signalHandlerID) {
            this.lbl.disconnect(signalHandlerID);
            this.lbl.set_text(last);
        }
    }
}
