#!/usr/bin/env python

from process import Process

class GlmRun(object):
    """
    Runs the exhaustive glm via connectir
    """
    
    def __init__(self, **options):
        """
        """
        super(GlmRun, self).__init__()
        self.options = []
        # defaults
        self.defaults = {'forks': 1, 'threads': 1, 'ztransform': True}
        self.set_options(**self.defaults)
        # additional
        self.set_options(**options)
        return
    
    def set_options(self, **kwrds):
        for key,value in kwrds.iteritems():
            self.set_option(key,value)
        return
    
    def set_option(self, key, value):
        setattr(self, key, value)
        self.options.append(key)
        return
    
    def _cmd(self):
        # TODO: check if options are set
        cmd = "connectir_glm.R"
        for key in self.options:
            value = getattr(self, key)
            if value:
                if type(value) is bool:
                    cmd += " --%s\n" % key
                else:
                    cmd += " --%s %s\n" % (key, value)
        return cmd
    
    def run(self):
        # TODO: have output put in real-time
        cmd = self._cmd()
        print cmd
        p = Process(cmd)
        print p.stdout

        if p.retcode != 0:
            raise Exception("Non-zero exit code!")
        
        return p
        

