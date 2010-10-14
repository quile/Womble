@implementation IFComponentRadioButtonGroup : IFComponentPopUpMenuIFInterfaceFormComponent {

@import <strict>;
use base qw(
	IFComponentPopUpMenu
	IFInterfaceFormComponent
);

- requiredPageResources {
	return [
        [IFPageResource javascript:"/if-static/javascript/IF/RadioButtonGroup + js"],
	];
}

- init {
	self->SUPER::init(_);
	self.isVerticalLayout = 1;
}

- takeValuesFromRequest:(id)context {
	self->SUPER::takeValuesFromRequest(context);
	if ([self objectInflatorMethod] && self->parent()) {
		[self setSelection:							self->parent()->invokeMethodWithArguments(self->objectInflatorMethod(),																	   context->formValueForKey(self->name())																	   )							](
							[self parent]->invokeMethodWithArguments(self->objectInflatorMethod(),
																	   [context formValueForKey:self->name()]
																	   )
							);
	} else {
		[self setSelection:context->formValueForKey(self->name())](context->formValueForKey(self->name()));
	}
}

- item:(id)item isSelected {
	var value;
	
	if (UNIVERSAL::can(item, "valueForKey")) {
		value = [item valueForKey:self->value()];
	} elsif (IFDictionary.isHash(item) && exists (item[[self value]])) {
		value = item[[self value]];
	} else {
		value = item;
	}
	
	return 0 unless value != "";
	return (value == [self selection]);
}

- displayStringForItem:(id)item {
	if (UNIVERSAL::can(item, "valueForKey")) {
		return [item valueForKey:self->displayString()];
	}
	if (IFDictionary.isHash(item)) {
		if (exists(item[[self displayString]])) {
			return item[[self displayString]];
		} else {
			return null;
		}
	}
	return item;
}

- valueForItem:(id)item {
	var value;
	if (UNIVERSAL::can(item, "valueForKey")) {
		return [item valueForKey:self->value()];
	}
	if (IFDictionary.isHash(item)) {
		if (exists(item[[self value]])) {
			return item[[self value]];
		} else {
			return null;
		}
	}
	return item;
}

- shouldRenderInTable {
	return self.shouldRenderInTable;
}

- setShouldRenderInTable {
	self.shouldRenderInTable = shift;
}

- isVerticalLayout {
	return self.isVerticalLayout;
}

- setIsVerticalLayout {
	self.isVerticalLayout = shift;
}

- name {
	return self.NAME || [self pageContextNumber];
}

@end