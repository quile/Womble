@implementation IFComponentRadioButton :  {

@import <strict>;
// use vars qw(@ISA);
@import <WM/Component>;
ISA = qw(IFComponent);

- takeValuesFromRequest:(id)context {
	self->SUPER::takeValuesFromRequest(context);
	[self setValue:context->formValueForKey(self->name()) forKey:"VALUE"];
	IFLog.debug("Value of input field " + [self name] + " is " + self->value());
}

- name {
	var name = self["NAME"];
	return name || [self queryKeyNameForPageAndLoopContexts];
}

- setName {
	self.NAME = shift;
}

- value {
	return self.VALUE;
}

- setValue {
	self.VALUE = shift;
}

- isChecked {
	return (!self.IS_CHECKED) if [self isNegated];
	return self.IS_CHECKED;
}

- setIsChecked {
	self.IS_CHECKED = shift;
}

- isNegated {
	return self.isNegated;
}

- setIsNegated {
	self.isNegated = shift;
}

@end