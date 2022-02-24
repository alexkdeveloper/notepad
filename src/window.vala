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
	[GtkTemplate (ui = "/com/github/alexkdeveloper/notepad/window.ui")]
	public class Window : Gtk.ApplicationWindow {
		[GtkChild]
		unowned Gtk.TreeView tree_view;
		[GtkChild]
		unowned Gtk.ListStore list_store;
		[GtkChild]
		unowned Gtk.TextView text_view;
		[GtkChild]
		unowned Gtk.Button add_button;
		[GtkChild]
		unowned Gtk.Button delete_button;
		[GtkChild]
		unowned Gtk.Button save_button;
		[GtkChild]
		unowned Gtk.Button save_as_button;
        
        private Gtk.Entry entry_name;

        private GLib.List<string> list;
		private string directory_path;
        private string item;
        private string note;

		public Window (Gtk.Application app) {
			Object (application: app);
			add_button.clicked.connect(on_add_clicked);
            delete_button.clicked.connect (on_delete_clicked);
            save_button.clicked.connect (on_save_clicked);
            save_as_button.clicked.connect(on_save_as_clicked);
            tree_view.cursor_changed.connect(on_select_item);
            var css_provider = new Gtk.CssProvider();
            try {
                     css_provider.load_from_data(".text_size {font-size: 15px}");
                     Gtk.StyleContext.add_provider_for_screen(Gdk.Screen.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
                 } catch (Error e) {
                     error ("Cannot load CSS stylesheet: %s", e.message);
             }
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
               alert("Choose a note");
               return;
           }
           GLib.File file = GLib.File.new_for_path(directory_path+"/"+item);
         var dialog_delete_file = new Gtk.MessageDialog(this, Gtk.DialogFlags.MODAL,Gtk.MessageType.QUESTION, Gtk.ButtonsType.OK_CANCEL, "Delete note "+file.get_basename()+" ?");
         dialog_delete_file.set_title("Question");
         Gtk.ResponseType result = (Gtk.ResponseType)dialog_delete_file.run ();
         dialog_delete_file.destroy();
         if(result==Gtk.ResponseType.OK){
         FileUtils.remove (directory_path+"/"+item);
         if(file.query_exists()){
            alert("Delete failed");
         }else{
             show_notes();
             text_view.buffer.text = "";
         }
      }
      }
      private void on_save_clicked(){
         var selection = tree_view.get_selection();
           selection.set_mode(Gtk.SelectionMode.SINGLE);
           Gtk.TreeModel model;
           Gtk.TreeIter iter;
           if (!selection.get_selected(out model, out iter)) {
               alert("Choose a note");
               if(!is_empty(text_view.buffer.text)){
                   note = text_view.buffer.text;
               }
               return;
           }
         if(is_empty(text_view.buffer.text)){
             alert("Nothing to save");
             return;
         }
         GLib.File file = GLib.File.new_for_path(directory_path+"/"+item);
        var dialog_save_file = new Gtk.MessageDialog(this, Gtk.DialogFlags.MODAL,Gtk.MessageType.QUESTION, Gtk.ButtonsType.OK_CANCEL, "Save note "+file.get_basename()+" ?");
         dialog_save_file.set_title("Question");
         Gtk.ResponseType result = (Gtk.ResponseType)dialog_save_file.run ();
         if(result==Gtk.ResponseType.OK){
         try {
            FileUtils.set_contents (file.get_path(), text_view.buffer.text);
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
          show_notes();
      }
      dialog_save_file.destroy();
      }

      private void on_save_as_clicked(){
        var selection = tree_view.get_selection();
           selection.set_mode(Gtk.SelectionMode.SINGLE);
           Gtk.TreeModel model;
           Gtk.TreeIter iter;
           if (!selection.get_selected(out model, out iter)) {
               alert("Choose a note");
               if(!is_empty(text_view.buffer.text)){
                   note = text_view.buffer.text;
               }
               return;
           }
        if(is_empty(text_view.buffer.text)){
             alert("Nothing to save");
             return;
         }
        var dialog_save_note = new Gtk.Dialog.with_buttons ("Save note", this, Gtk.DialogFlags.MODAL);
		var content_area = dialog_save_note.get_content_area ();
        entry_name = new Gtk.Entry();
        var label_name = new Gtk.Label.with_mnemonic ("_Name:");
        var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 20);
        hbox.set_border_width(15);
        hbox.pack_start (label_name, false, true, 0);
        hbox.pack_start (entry_name, true, true, 0);
		content_area.add (hbox);
		dialog_save_note.add_button ("OK", Gtk.ResponseType.OK);
		dialog_save_note.add_button ("CLOSE", Gtk.ResponseType.CLOSE);
		dialog_save_note.response.connect (on_save_response);
		dialog_save_note.show_all ();
      }

      private void on_save_response (Gtk.Dialog dialog, int response_id) {
        switch (response_id) {
		case Gtk.ResponseType.OK:
		if(is_empty(entry_name.get_text())){
		    alert("Enter the name");
            entry_name.grab_focus();
            return;
		}
		GLib.File select_file = GLib.File.new_for_path(directory_path+"/"+item);
		GLib.File edit_file = GLib.File.new_for_path(directory_path+"/"+entry_name.get_text().strip());
		if (select_file.get_basename() != edit_file.get_basename() && !edit_file.query_exists()){
                FileUtils.rename(select_file.get_path(), edit_file.get_path());
                if(!edit_file.query_exists()){
                    alert("Rename failed");
                    return;
                }
                try {
                 FileUtils.set_contents (edit_file.get_path(), text_view.buffer.text);
              } catch (Error e) {
                     stderr.printf ("Error: %s\n", e.message);
            }
            }else{
                if (select_file.get_basename() != edit_file.get_basename()) {
                    alert("A note with the same name already exists");
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
            text_view.buffer.text = text;
            if (is_empty(text)&&!is_empty(note)){
                text_view.buffer.text = note;
                note = "";
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

    private void alert (string str){
          var dialog_alert = new Gtk.MessageDialog(this, Gtk.DialogFlags.MODAL, Gtk.MessageType.INFO, Gtk.ButtonsType.OK, str);
          dialog_alert.set_title("Message");
          dialog_alert.run();
          dialog_alert.destroy();
       }
    }
}
