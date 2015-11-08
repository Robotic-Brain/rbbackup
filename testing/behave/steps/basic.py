from behave import *
import parse

class StepOrderError(Exception):
    """
    This error is raised if 2 or more steps need to be executed in a specific order
    """
    pass

@given(u'there is an argument "{arg}"')
def step_impl(context, arg):
    if context.data['executed']:
        raise StepOrderError('Setting arguments after programm invocation has no effect!')

    context.data['arguments'].append(arg)

@when(u'I run trough a terminal')
def step_impl(context):
    import subprocess
    command = ['python', context.data['module_path']] + context.data['arguments']
    context.data['result'] = subprocess.run(
                                command,
                                input=context.data['stdin'],
                                stdout=subprocess.PIPE,
                                stderr=subprocess.PIPE,
                                timeout=context.data['run_timeout'],
                                universal_newlines=context.data['textmode']
                             )
    context.data['executed'] = True

@parse.with_pattern(r"(?i)stdout|stderr")
def parse_OStreamType(text):
    """
    Returns false if text is STDERR true if STDOUT
    """
    return text.upper() == "STDOUT"

register_type(OStream=parse_OStreamType)

@then(u'{stdout:OStream} should contain "{text}"')
def step_impl(context, stdout, text):
    streamName = 'STDOUT' if stdout else 'STDERR'
    actual = context.data['result'].stdout if stdout else context.data['result'].stderr
    assert text in actual, (
            "Actual output: \n"+
            "----- BEGIN "+streamName+" -----\n"+
            actual+
            "------ END "+streamName+" ------"
        )

@then(u'Stdout should contain the actual version')
def step_impl(context):
    raise NotImplementedError(u'STEP: Then Stdout should contain the actual version')

@then(u'the exit code should be {code:d}')
def step_impl(context, code):
    actual = context.data['result'].returncode
    assert code == actual, "Actual code: "+str(actual)
