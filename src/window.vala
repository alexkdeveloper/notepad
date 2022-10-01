/* window.vala
 *
 * Copyright 2021 Alex
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

namespace Notepad {
	public class Window : Adw.ApplicationWindow {
		private Gtk.TreeView tree_view;
		private Gtk.ListStore list_store;
		private Gtk.TextView text_view;
		private Gtk.Button add_button;
		private Gtk.Button delete_button;
		private Gtk.Button save_button;
		private Gtk.Button save_as_button;
        
        private Gtk.Entry entry_name;

        private GLib.List<string> list;
        private Adw.ToastOverlay overlay;
		private string directory_path;
        private string item = "";
        private string note = "";

		public Window (Adw.Application app) {
			Object (application: app, title: "Notepad",
            default_height: 300,
            default_width: 550);
			add_button.clicked.connect(on_add_clicked);
            delete_button.clicked.connect (on_delete_clicked);
            save_button.clicked.connect (on_save_clicked);
            save_as_button.clicked.connect(on_save_as_clicked);
            tree_view.cursor_changed.connect(on_select_item);
            var css_provider = new Gtk.CssProvider();
            css_provider.load_from_data((uint8[])".text_size {font-size: 15px}");
            Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            text_view.get_style_context().add_class("text_size");
			directory_path = Environment.get_user_data_dir()+"/notes_for_notepad_app";
   GLib.File file = GLib.File.new_for_path(directory_path);
   if(!file.query_exists()){
     try{
        file.make_directory();
     }catch(Error e){
        stderr.printf ("Error: %s\n", e.message);
     }
		}
		show_notes();
	}
    construct{
        list_store = new Gtk.ListStore(Columns.N_COLUMNS, typeof(string));
           tree_view = new Gtk.TreeView.with_model(list_store);
           var text = new Gtk.CellRendererText ();
           var column = new Gtk.TreeViewColumn ();
           column.pack_start (text, true);
           column.add_attribute (text, "markup", Columns.TEXT);
           tree_view.append_column (column);
           tree_view.set_headers_visible (false);
           tree_view.cursor_changed.connect(on_select_item);
        var scroll = new Gtk.ScrolledWindow ();
        scroll.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scroll.set_vexpand(true);
        scroll.set_propagate_natural_width(true);
        scroll.set_child (this.tree_view);

        text_view = new Gtk.TextView();
        text_view.wrap_mode = Gtk.WrapMode.WORD;
        var scroll_for_text = new Gtk.ScrolledWindow ();
        scroll_for_text.set_policy (Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC);
        scroll_for_text.set_vexpand(true);
        scroll_for_text.set_hexpand(true);
        scroll_for_text.set_child (this.text_view);

        add_button = new Gtk.Button ();
            add_button.set_icon_name ("list-add-symbolic");
            add_button.vexpand = false;
            add_button.tooltip_text = _("Add Note");
        delete_button = new Gtk.Button ();
            delete_button.set_icon_name ("list-remove-symbolic");
            delete_button.vexpand = false;
            delete_button.tooltip_text = _("Delete Note");
        save_button = new Gtk.Button ();
            save_button.set_icon_name ("document-save-symbolic");
            save_button.vexpand = false;
            save_button.tooltip_text = _("Save Note");
        save_as_button = new Gtk.Button ();
            save_as_button.set_icon_name ("document-save-as-symbolic");
            save_as_button.vexpand = false;
            save_as_button.tooltip_text = _("Save Note as…");

        var headerbar = new Adw.HeaderBar();
        headerbar.pack_start(add_button);
        headerbar.pack_start(delete_button);
        headerbar.pack_start(save_button);
        headerbar.pack_start(save_as_button);

        var box = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        box.append(scroll);
        box.append(scroll_for_text);
        overlay = new Adw.ToastOverlay();
        overlay.set_child(box);
        var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_box.append(headerbar);
        main_box.append(overlay);
        set_content(main_box);
    }
      private void on_add_clicked(){
        GLib.File file = GLib.File.new_for_path(directory_path+"/"+date_time());
        try {
            FileUtils.set_contents (file.get_path(), "");
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
         show_notes();
      }
      private void on_delete_clicked(){
         var selection = tree_view.get_selection();
           selection.set_mode(Gtk.SelectionMode.SINGLE);
           Gtk.TreeModel model;
           Gtk.TreeIter iter;
           if (!selection.get_selected(out model, out iter)) {
               set_toast(_("Choose a note"));
               return;
           }
           GLib.File file = GLib.File.new_for_path(directory_path+"/"+item);
      var delete_note_dialog = new Adw.MessageDialog(this, _("Delete note ")+file.get_basename()+"?", "");
            delete_note_dialog.add_response("cancel", _("_Cancel"));
            delete_note_dialog.add_response("ok", _("_OK"));
            delete_note_dialog.set_default_response("ok");
            delete_note_dialog.set_close_response("cancel");
            delete_note_dialog.set_response_appearance("ok", SUGGESTED);
            delete_note_dialog.show();
            delete_note_dialog.response.connect((response) => {
                if (response == "ok") {
                     FileUtils.remove (directory_path+"/"+item);
                      if(file.query_exists()){
                         set_toast(_("Delete failed"));
                      }else{
                         show_notes();
                         text_view.buffer.text = "";
                      }
                }
                delete_note_dialog.close();
            });
      }
      private void on_save_clicked(){
         var selection = tree_view.get_selection();
           selection.set_mode(Gtk.SelectionMode.SINGLE);
           Gtk.TreeModel model;
           Gtk.TreeIter iter;
           if (!selection.get_selected(out model, out iter)) {
               set_toast(_("Choose a note"));
               if(!is_empty(text_view.buffer.text)){
                   note = text_view.buffer.text;
               }
               return;
           }
         if(is_empty(text_view.buffer.text)){
             set_toast(_("Nothing to save"));
             return;
         }
         GLib.File file = GLib.File.new_for_path(directory_path+"/"+item);
         var save_note_dialog = new Adw.MessageDialog(this, _("Save note ")+file.get_basename()+"?", "");
            save_note_dialog.add_response("cancel", _("_Cancel"));
            save_note_dialog.add_response("ok", _("_OK"));
            save_note_dialog.set_default_response("ok");
            save_note_dialog.set_close_response("cancel");
            save_note_dialog.set_response_appearance("ok", SUGGESTED);
            save_note_dialog.show();
            save_note_dialog.response.connect((response) => {
                if (response == "ok") {
                     try {
                        FileUtils.set_contents (file.get_path(), text_view.buffer.text);
                    } catch (Error e) {
                        stderr.printf ("Error: %s\n", e.message);
                    }
                      show_notes();
                }
                save_note_dialog.close();
            });
      }

      private void on_save_as_clicked(){
        var selection = tree_view.get_selection();
           selection.set_mode(Gtk.SelectionMode.SINGLE);
           Gtk.TreeModel model;
           Gtk.TreeIter iter;
           if (!selection.get_selected(out model, out iter)) {
               set_toast(_("Choose a note"));
               if(!is_empty(text_view.buffer.text)){
                   note = text_view.buffer.text;
               }
               return;
           }
        if(is_empty(text_view.buffer.text)){
             set_toast(_("Nothing to save"));
             return;
         }
        var dialog_save_note = new Gtk.Dialog.with_buttons (_("Save note"), this, Gtk.DialogFlags.MODAL);
		var content_area = dialog_save_note.get_content_area ();
        entry_name = new Gtk.Entry();
        var label_name = new Gtk.Label.with_mnemonic (_("_Name:"));
        label_name.set_xalign (0);
        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        vbox.margin_start = 10;
        vbox.margin_end = 10;
        vbox.margin_top = 10;
        vbox.margin_bottom = 10;
        vbox.append (label_name);
        vbox.append (entry_name);
		content_area.append (vbox);
		dialog_save_note.add_button (_("_Close"), Gtk.ResponseType.CLOSE);
		dialog_save_note.add_button (_("_OK"), Gtk.ResponseType.OK);
		dialog_save_note.response.connect (on_save_response);
		dialog_save_note.show ();
      }

      private void on_save_response (Gtk.Dialog dialog, int response_id) {
        switch (response_id) {
		case Gtk.ResponseType.OK:
		if(is_empty(entry_name.get_text())){
		    set_toast(_("Enter the name"));
            entry_name.grab_focus();
            return;
		}
		GLib.File select_file = GLib.File.new_for_path(directory_path+"/"+item);
		GLib.File edit_file = GLib.File.new_for_path(directory_path+"/"+entry_name.get_text().strip());
		if (select_file.get_basename() != edit_file.get_basename() && !edit_file.query_exists()){
                FileUtils.rename(select_file.get_path(), edit_file.get_path());
                if(!edit_file.query_exists()){
                    set_toast(_("Rename failed"));
                    return;
                }
                try {
                 FileUtils.set_contents (edit_file.get_path(), text_view.buffer.text);
              } catch (Error e) {
                     stderr.printf ("Error: %s\n", e.message);
            }
            }else{
                if (select_file.get_basename() != edit_file.get_basename()) {
                    alert(_("A note with the same name already exists"),"");
                    entry_name.grab_focus();
                    return;
                }
                try {
                 FileUtils.set_contents (edit_file.get_path(), text_view.buffer.text);
              } catch (Error e) {
                     stderr.printf ("Error: %s\n", e.message);
             }
            }
            show_notes();
        dialog.destroy();
		break;
	case Gtk.ResponseType.CLOSE:
	        dialog.destroy();
	        break;
	case Gtk.ResponseType.DELETE_EVENT:
		dialog.destroy();
		break;
		}
}

      private void on_select_item () {
           var selection = tree_view.get_selection();
           selection.set_mode(Gtk.SelectionMode.SINGLE);
           Gtk.TreeModel model;
           Gtk.TreeIter iter;
           if (!selection.get_selected(out model, out iter)) {
               return;
           }
           Gtk.TreePath path = model.get_path(iter);
           var index = int.parse(path.to_string());
           if (index >= 0) {
               item = list.nth_data(index);
           }
          string text;
            try {
                FileUtils.get_contents (directory_path+"/"+item, out text);
            } catch (Error e) {
               stderr.printf ("Error: %s\n", e.message);
            }
            if (is_empty(text)&&!is_empty(note)){
                text_view.buffer.text = note;
                Timeout.add_seconds(1,()=>{
                    note = "";
                    return false;
                });
            }else{
                text_view.buffer.text = text;
            }
       }

      private void show_notes () {
           list_store.clear();
           list = new GLib.List<string> ();
            try {
            Dir dir = Dir.open (directory_path, 0);
            string? file_name = null;
            while ((file_name = dir.read_name ()) != null) {
                list.append(file_name);
            }
        } catch (FileError err) {
            stderr.printf (err.message);
        }
         Gtk.TreeIter iter;
           foreach (string item in list) {
               list_store.append(out iter);
               list_store.set(iter, Columns.TEXT, item);
           }
       }

       private bool is_empty(string str){
        return str.strip().length == 0;
      }

       private enum Columns {
           TEXT, N_COLUMNS
       }

    private string date_time(){
         var now = new DateTime.now_local ();
         return now.format("%d")+"."+now.format("%m")+"."+now.format("%Y")+"  "+now.format("%H")+":"+now.format("%M")+":"+now.format("%S");
    }
    private void set_toast (string str){
        var toast = new Adw.Toast(str);
        toast.set_timeout(3);
        overlay.add_toast(toast);
    }
    private void alert (string heading, string body){
            var dialog_alert = new Adw.MessageDialog(this, heading, body);
            if (body != "") {
                dialog_alert.set_body(body);
            }
            dialog_alert.add_response("ok", _("_OK"));
            dialog_alert.set_response_appearance("ok", SUGGESTED);
            dialog_alert.response.connect((_) => { dialog_alert.close(); });
            dialog_alert.show();
        }
    }
}
