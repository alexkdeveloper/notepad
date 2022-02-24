notepad_sources = [
  'main.vala',
  'window.vala',
]

notepad_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
]

gnome = import('gnome')

notepad_sources += gnome.compile_resources('notepad-resources',
  'notepad.gresource.xml',
  c_name: 'notepad'
)

executable('com.github.alexkdeveloper.notepad', notepad_sources,
  vala_args: '--target-glib=2.50',  dependencies: notepad_deps,
  install: true,
)
