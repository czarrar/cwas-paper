from string import Template
import yaml 

class YamlReader(object):
    """Reads yaml file specifically for my scripts"""
    def __init__(self, filename):
        super(YamlReader, self).__init__()
        # Load variables/data
        f = open(filename, 'r')
        self.yaml_data = yaml.load(f)
        f.close()
        # Parse some
        self._set_general()
        return
    
    def _set_general(self):
        self.data = {}
        for k,v in self.yaml_data['general'].iteritems():
            self.data[k] = v
        return
    
    def _parse(self, name):        
        setattr(self, name, {})
        class_data = getattr(self, name)
        # limit to 5 loops...
        for i in range(5):
            for k,v in self.yaml_data[name].iteritems():
                class_data[k] = Template(str(v)).safe_substitute(self.data)
        return
        
    def compile(self):
        for i in range(5):
            for k,v in self.data.iteritems():
                self.data[k] = Template(str(v)).safe_substitute(self.data)
        for k in self.yaml_data:
            self._parse(k)
        return
