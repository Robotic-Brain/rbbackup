def before_scenario(context, scenario):
	context.data = {
		'executed': False,
		'arguments': []
	}
