import sublime, sublime_plugin
import re
import os.path

# Extends TextCommand so that run() receives a View to modify.  
class EasyTestCommand(sublime_plugin.TextCommand):  
    def convertToObject(self, filename, suffix):
        return re.sub(r'(.+){sfx}/(.+)_{sfx}.rb'.format(sfx=suffix),
               r'\1app/\2.rb', filename)

    def run(self, edit):  
        filename = self.view.file_name()
        switched_file = ""
        if filename.endswith("_test.rb"):
            switched_file = self.convertToObject(filename, "test")
        elif filename.endswith("_spec.rb"):
            switched_file = self.convertToObject(filename, "spec")
        else:
            test_file = re.sub(r'(.+)app/(.+)\.rb', r'\1test/\2_test.rb', filename)
            spec_file = re.sub(r'(.+)app/(.+)\.rb', r'\1spec/\2_spec.rb', filename)
            if os.path.exists(test_file):
                switched_file = test_file
            elif os.path.exists(spec_file):
                switched_file = spec_file

        if switched_file:
            self.view.window().open_file(switched_file)
