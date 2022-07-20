project('notepad', ['c', 'vala'],
          version: '0.1.0',
    meson_version: '>= 0.50.0',
  default_options: [ 'warning_level=2',
                   ],
)

i18n = import('i18n')

config_h_dir = include_directories('.')

conf = configuration_data()
conf.set_quoted('GETTEXT_PACKAGE', meson.project_name())
conf.set_quoted('LOCALEDIR', join_paths(get_option('prefix'), get_option('localedir')))
configure_file(output: 'config.h', configuration: conf)

subdir('data')
subdir('src')
subdir('po')

gnome = import('gnome')

gnome.post_install(
  glib_compile_schemas: false,
  gtk_update_icon_cache: true,
  update_desktop_database: true
)
