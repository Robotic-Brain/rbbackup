from behave import *

@given(u'there is an argument "{arg}"')
def step_impl(context, arg):
    if context.data['executed']:
        raise StepOrderError('Setting arguments after programm invokation has no effect!')
        
    context.data['arguments'].append(arg)

@when(u'I run trough a terminal')
def step_impl(context):
    raise NotImplementedError(u'STEP: When I run trough a terminal')

@then(u'Stdout should contain "{text}"')
def step_impl(context, text):
    raise NotImplementedError(u'STEP: Then Stdout should contain "'+text+u'"')

@then(u'Stdout should contain the actual version')
def step_impl(context):
    raise NotImplementedError(u'STEP: Then Stdout should contain the actual version')

@then(u'the exit code should be {code:d}')
def step_impl(context, code):
    raise NotImplementedError(u'STEP: Then the exit code should be '+code)
