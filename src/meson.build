notepad_sources = [
  'main.vala',
  'window.vala',
]

notepad_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk4', version: '>= 3.22'),
  dependency('libadwaita-1')
]

gnome = import('gnome')

executable('com.github.alexkdeveloper.notepad', notepad_sources, 
include_directories: config_h_dir, 
vala_args: ['--target-glib=2.50', meson.source_root() + '/src/config.vapi'], 
c_args: ['-include', 'config.h'], 
  dependencies: notepad_deps,
  install: true,
)
