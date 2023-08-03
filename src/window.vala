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
		private Gtk.ListBox list_box;
		private Gtk.TextView text_view;
		private Gtk.Button add_button;
		private Gtk.Button delete_button;
        private Gtk.Button search_button;
		private Gtk.Button save_button;
		private Gtk.Button save_as_button;
        
        private Gtk.Entry entry_name;
        private Gtk.SearchEntry entry_search;

        private Adw.Window window_save_note;
        private Adw.ToastOverlay overlay;

        private string last_note_directory_path;
		private string directory_path;
        private string item = "";
        private string note = "";

		public Window (Adw.Application application) {
			Object (application: application, title: "Notepad",
            default_height: 400,
            default_width: 700);
			add_button.clicked.connect(on_add_clicked);
            delete_button.clicked.connect(on_delete_clicked);
            save_button.clicked.connect(on_save_clicked);
            save_as_button.clicked.connect(on_save_as_clicked);
            search_button.clicked.connect(on_search_clicked);
            var css_provider = new Gtk.CssProvider();
            css_provider.load_from_data((uint8[])".text_size {font-size: 18px}");
            Gtk.StyleContext.add_provider_for_display(Gdk.Display.get_default(), css_provider, Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION);
            text_view.get_style_context().add_class("text_size");
	}
    construct{
        list_box = new Gtk.ListBox ();
        list_box.vexpand = true;
        list_box.row_selected.connect(on_select_item);
        var scroll = new Gtk.ScrolledWindow () {
            propagate_natural_height = true,
            propagate_natural_width = true
        };

        scroll.set_child(list_box);

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
        search_button = new Gtk.Button();
            search_button.set_icon_name("edit-find-symbolic");
            search_button.vexpand = false;
            search_button.tooltip_text = _("Search for Notes");
        save_button = new Gtk.Button ();
            save_button.set_icon_name ("document-save-symbolic");
            save_button.vexpand = false;
            save_button.tooltip_text = _("Save Note");
        save_as_button = new Gtk.Button ();
            save_as_button.set_icon_name ("document-save-as-symbolic");
            save_as_button.vexpand = false;
            save_as_button.tooltip_text = _("Save Note as…");
         var menu_button = new Gtk.MenuButton();
            menu_button.set_icon_name ("open-menu-symbolic");
            menu_button.vexpand = false;

        var headerbar = new Adw.HeaderBar();
        headerbar.pack_start(add_button);
        headerbar.pack_start(delete_button);
        headerbar.pack_start(search_button);
        headerbar.pack_end(menu_button);
        headerbar.pack_end(save_as_button);
        headerbar.pack_end(save_button);

        var about_action = new GLib.SimpleAction ("about", null);
        about_action.activate.connect (about);
        var quit_action = new GLib.SimpleAction ("quit", null);
        quit_action.activate.connect(()=>{
            on_close_application();
        });
        var app = GLib.Application.get_default();
        app.add_action(about_action);
        app.add_action(quit_action);
        var menu = new GLib.Menu();
        var item_about = new GLib.MenuItem (_("About Notepad"), "app.about");
        var item_quit = new GLib.MenuItem (_("Quit"), "app.quit");
        menu.append_item (item_about);
        menu.append_item (item_quit);
        var popover = new Gtk.PopoverMenu.from_model(menu);
        menu_button.set_popover(popover);

        entry_search = new Gtk.SearchEntry();
        entry_search.hexpand = true;
        entry_search.changed.connect(show_notes);
        entry_search.margin_start = 35;
        entry_search.margin_end = 35;
        entry_search.margin_top = 10;
        entry_search.margin_bottom = 5;
        entry_search.hide();

        var hbox = new Gtk.Box(Gtk.Orientation.HORIZONTAL, 5);
        hbox.append(scroll);
        hbox.append(scroll_for_text);
        var box = new Gtk.Box(Gtk.Orientation.VERTICAL, 5);
        box.append(entry_search);
        box.append(hbox);
        overlay = new Adw.ToastOverlay();
        overlay.set_child(box);
        var main_box = new Gtk.Box(Gtk.Orientation.VERTICAL, 0);
        main_box.append(headerbar);
        main_box.append(overlay);
        set_content(main_box);

        close_request.connect(on_close_application);

        directory_path = Environment.get_user_data_dir()+"/notes_for_notepad_app";
   GLib.File file = GLib.File.new_for_path(directory_path);
   if(!file.query_exists()){
     try{
        file.make_directory();
     }catch(Error e){
        stderr.printf ("Error: %s\n", e.message);
     }
		}
		 last_note_directory_path = Environment.get_user_data_dir()+"/last-note";
   GLib.File last_note_directory = GLib.File.new_for_path(last_note_directory_path);
   if(!last_note_directory.query_exists()){
     try{
        last_note_directory.make_directory();
     }catch(Error e){
        stderr.printf ("Error: %s\n", e.message);
     }
   }
		show_notes();

        GLib.File last_note_name_file = GLib.File.new_for_path(last_note_directory_path+"/name");
           if(last_note_name_file.query_exists()){
            string last_note_name;
               try{
               FileUtils.get_contents(last_note_name_file.get_path(), out last_note_name);
               }catch(Error e){
                  stderr.printf ("Error: %s\n", e.message);
              }
             list_box.select_row(list_box.get_row_at_index(get_index(last_note_name)));
        }

        var event_controller = new Gtk.EventControllerKey ();
        event_controller.key_pressed.connect ((keyval, keycode, state) => {
            if (Gdk.ModifierType.CONTROL_MASK in state && keyval == Gdk.Key.q) {
                 on_close_application();
            }

            if (Gdk.ModifierType.CONTROL_MASK in state && keyval == Gdk.Key.n) {
                 on_add_clicked();
            }

             if (Gdk.ModifierType.CONTROL_MASK in state && (keyval == Gdk.Key.d || keyval == Gdk.Key.r)) {
                 on_delete_clicked();
            }

             if (Gdk.ModifierType.CONTROL_MASK in state && keyval == Gdk.Key.s) {
                 on_save_clicked();
            }

             if (Gdk.ModifierType.CONTROL_MASK in state && Gdk.ModifierType.SHIFT_MASK in state && keyval == Gdk.Key.S) {
                 on_save_as_clicked();
            }

             if (Gdk.ModifierType.CONTROL_MASK in state && keyval == Gdk.Key.f) {
                 on_search_clicked();
            }

            return false;
        });
        ((Gtk.Widget)this).add_controller(event_controller);
    }
      private void on_add_clicked(){
        GLib.File file = GLib.File.new_for_path(directory_path+"/"+date_time());
        try {
            FileUtils.set_contents (file.get_path(), "");
        } catch (Error e) {
            stderr.printf ("Error: %s\n", e.message);
        }
         show_notes();
         list_box.select_row(list_box.get_row_at_index(get_index(file.get_basename())));
      }
      private void on_delete_clicked(){
          var selection = list_box.get_selected_row();
          if (!selection.is_selected()) {
             set_toast(_("Choose a note"));
             return;
          }
           GLib.File file = GLib.File.new_for_path(directory_path+"/"+item);
      var delete_note_dialog = new Adw.MessageDialog(this, _("Delete Note?"), _("Delete note “%s”?").printf(file.get_basename()));
            delete_note_dialog.add_response("cancel", _("_Cancel"));
            delete_note_dialog.add_response("ok", _("_OK"));
            delete_note_dialog.set_default_response("ok");
            delete_note_dialog.set_close_response("cancel");
            delete_note_dialog.set_response_appearance("ok", DESTRUCTIVE);
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
        var selection = list_box.get_selected_row();
          if (!selection.is_selected()) {
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
         var save_note_dialog = new Adw.MessageDialog(this, _("Save Note?"), _("Save note “%s”?").printf(file.get_basename()));
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
                     list_box.select_row(list_box.get_row_at_index(get_index(file.get_basename())));
                }
                save_note_dialog.close();
            });
      }

      private void on_save_as_clicked(){
        var selection = list_box.get_selected_row();
          if (!selection.is_selected()) {
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
        window_save_note = new Adw.Window();
        window_save_note.set_title (_("Save note"));
        window_save_note.set_transient_for (this);
        entry_name = new Gtk.Entry();
        var label_name = new Gtk.Label.with_mnemonic (_("_Name:"));
        label_name.set_xalign (0);
        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        vbox.append (label_name);
        vbox.append (entry_name);
        var ok_button = new Gtk.Button.with_label (_("OK"));
        ok_button.clicked.connect(on_ok_clicked);
        var close_button = new Gtk.Button.with_label (_("Close"));
        close_button.clicked.connect(()=>{
           window_save_note.close();
        });
		var hbox = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);
        hbox.set_halign (Gtk.Align.END);
        hbox.append (close_button);
        hbox.append (ok_button);

        var box = new Gtk.Box (Gtk.Orientation.VERTICAL, 10);
        box.vexpand = true;
        box.append (vbox);
        box.append (hbox);

        var clamp = new Adw.Clamp ();
        clamp.valign = Gtk.Align.CENTER;
        clamp.tightening_threshold = 100;
        clamp.margin_top = 10;
        clamp.margin_bottom = 20;
        clamp.margin_start = 20;
        clamp.margin_end = 20;
        clamp.set_child (box);

        var headerbar = new Adw.HeaderBar();
        headerbar.add_css_class("flat");

        var main_box = new Gtk.Box (Gtk.Orientation.VERTICAL, 0);
        main_box.append (headerbar);
        main_box.append (clamp);

        window_save_note.set_content (main_box);
        window_save_note.show();
      }

      private void on_ok_clicked () {
		if(is_empty(entry_name.get_text())){
		    alert(_("Enter the name"),"");
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
            list_box.select_row(list_box.get_row_at_index(get_index(edit_file.get_basename())));
            window_save_note.close();
      }

      private void on_search_clicked(){
          if(entry_search.is_visible()){
                  entry_search.hide();
                  entry_search.set_text("");
                  if(item != ""){
                    list_box.select_row(list_box.get_row_at_index(get_index(item)));
                  }
               }else{
                  entry_search.show();
                  entry_search.grab_focus();
               }
    }

    private bool on_close_application(){
        var app = GLib.Application.get_default();
           GLib.File file = GLib.File.new_for_path(directory_path+"/"+item);
           if(item != "" && file.query_exists()){
           string note_text;
            try {
                FileUtils.get_contents (file.get_path(), out note_text);
            } catch (Error e) {
               stderr.printf ("Error: %s\n", e.message);
            }
            string edit_text = text_view.buffer.text;
        if(note_text != edit_text){
        var save_changes_dialog = new Adw.MessageDialog(this, _("Changes are not saved"), _("Save changes to the current note before exiting the program?"));
            save_changes_dialog.add_response("cancel", _("_Cancel"));
            save_changes_dialog.add_response("ok", _("_OK"));
            save_changes_dialog.set_default_response("ok");
            save_changes_dialog.set_close_response("cancel");
            save_changes_dialog.set_response_appearance("ok", SUGGESTED);
            save_changes_dialog.show();
            save_changes_dialog.response.connect((response) => {
                if (response == "ok") {
                try {
                 FileUtils.set_contents (file.get_path(), edit_text);
              } catch (Error e) {
                     stderr.printf ("Error: %s\n", e.message);
             }
                 }
                save_changes_dialog.close();
                app.quit();
            });
        }else{
            app.quit();
        }
    }else{
         app.quit();
       }
       return true;
    }

      private void on_select_item () {
        var selection = list_box.get_selected_row();
           if (!selection.is_selected()) {
               return;
           }
           string prev_item = item;
           GLib.File file = GLib.File.new_for_path(directory_path+"/"+prev_item);
           if(prev_item != "" && file.query_exists()){
           string note_text;
            try {
                FileUtils.get_contents (file.get_path(), out note_text);
            } catch (Error e) {
               stderr.printf ("Error: %s\n", e.message);
            }
            string edit_text = text_view.buffer.text;
        if(note_text != edit_text){
        var save_changes_dialog = new Adw.MessageDialog(this, _("Changes are not saved"), _("Save the changes in the previous note?"));
            save_changes_dialog.add_response("cancel", _("_Cancel"));
            save_changes_dialog.add_response("ok", _("_OK"));
            save_changes_dialog.set_default_response("ok");
            save_changes_dialog.set_close_response("cancel");
            save_changes_dialog.set_response_appearance("ok", SUGGESTED);
            save_changes_dialog.show();
            save_changes_dialog.response.connect((response) => {
                if (response == "ok") {
                try {
                 FileUtils.set_contents (file.get_path(), edit_text);
              } catch (Error e) {
                     stderr.printf ("Error: %s\n", e.message);
              }
                show_notes();
                list_box.select_row(list_box.get_row_at_index(get_index(item)));
            }
                save_changes_dialog.close();
            });
        }
    }
          GLib.Value value = "";
          selection.get_property("title", ref value);
          item = value.get_string();
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
             try{
               FileUtils.set_contents(last_note_directory_path+"/name", item);
            }catch(Error e){
                stderr.printf ("Error: %s\n", e.message);
            }
       }

      private void show_notes () {
           var list = new GLib.List<string> ();
            try {
            Dir dir = Dir.open (directory_path, 0);
            string? name = null;
            while ((name = dir.read_name ()) != null) {
                 if(entry_search.is_visible()){
                    if(name.down().contains(entry_search.get_text().down())){
                       list.append(name);
                    }
                    }else{
                       list.append(name);
                }
            }
        } catch (FileError err) {
            stderr.printf (err.message);
        }
        for (
            var child = (Gtk.ListBoxRow) list_box.get_last_child ();
                child != null;
                child = (Gtk.ListBoxRow) list_box.get_last_child ()
        ) {
            list_box.remove(child);
        }
           foreach (string item in list) {
              string text;
                try {
                  FileUtils.get_contents (directory_path+"/"+item, out text);
               } catch (Error e) {
                stderr.printf ("Error: %s\n", e.message);
               }
               text = text.strip();
               string sub_item = "";
               if(text.length > 16){
                  string[] array = new string[16];
                  for (int i=0;i<16;i++) {
                       array[i] = text.get_char(text.index_of_nth_char(i)).to_string();
                       sub_item = sub_item + array[i];
                  }
                }else{
                    sub_item = text;
                }
                var row = new Adw.ActionRow () {
                title = item,
                subtitle = sub_item
            };
            list_box.append(row);
           }
       }

        private int get_index(string item){
            int index_of_item = 0;
            try {
            Dir dir = Dir.open (directory_path, 0);
            string? name = null;
            int index = 0;
            while ((name = dir.read_name ()) != null) {
                index++;
                if(name == item){
                  index_of_item = index - 1;
                  break;
                }
            }
        } catch (FileError err) {
            stderr.printf (err.message);
          }
          return index_of_item;
        }

       private bool is_empty(string str){
        return str.strip().length == 0;
      }

    private void about () {
	        var win = new Adw.AboutWindow () {
                application_name = "Notepad",
                application_icon = "com.github.alexkdeveloper.notepad",
                version = "1.2.2",
                copyright = "Copyright © 2022-2023 Alex Kryuchkov",
                license_type = Gtk.License.GPL_3_0,
                developer_name = "Alex Kryuchkov",
                developers = {"Alex Kryuchkov https://github.com/alexkdeveloper"},
                translator_credits = _("translator-credits"),
                website = "https://github.com/alexkdeveloper/notepad",
                issue_url = "https://github.com/alexkdeveloper/notepad/issues"
            };
            win.set_transient_for (this);
            win.show ();
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
