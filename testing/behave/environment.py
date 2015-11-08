def before_scenario(context, scenario):
    import os
    context.data = {
        'executed': False,
        'arguments': [],
        'stdin': None,
        'run_timeout': None,
        'module_path': os.path.abspath(os.path.dirname(os.path.abspath(__file__))+'/../../rbbackup'),
        'textmode': True
    }
