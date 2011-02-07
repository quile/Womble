/* --------------------------------------------------------------------
 * WM - Web Framework and ORM heavily influenced by WebObjects & EOF
 * The MIT License
 *
 * Copyright (c) 2010 kd
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

@import <WM/WMComponent.j>
@import <WM/WMPageResource.j>
@import <WM/WMComponents.j>

@implementation WMTestForm : WMComponent
{
    id radioButtonGroup @accessors;
    id checkBoxGroup @accessors;
    id textFieldValue @accessors;
    id hiddenFieldValue @accessors;
    id textValue @accessors;
    id scrollingList @accessors;
    id popUpMenu @accessors;
    id selection @accessors;
}

// testing page resources
- (id) requiredPageResoures {
    return []
}

- (id) init {
    // initial values to make sure they're populated correctly
    radioButtonGroup = "D";
    checkBoxGroup = ["F", "S"];
    textFieldValue = "Spohr, Ludwig";
    textValue = "Dussek, Jan Ladislav";
    hiddenFieldValue = "Hummel, Johann Nepomuk";
    popUpMenu = "G";
    scrollingList = ["H", "V"];
    selection = ["B"];
    return [super init];
}


- (CPDictionary) Bindings {
    return {
        form: {
            type: "Form",
        },
        radio_button_group: {
            type: "RadioButtonGroup",
            bindings: {
                list: [
                    { value: '', displayString: 'None', },
                    { value: 'A', displayString: 'Arne, Thomas', },
                    { value: 'C', displayString: 'Cramer, Johann Baptist', },
                    { value: 'D', displayString: 'Delius, Frederick', },
                    { value: 'H', displayString: 'Holst, Gustav', },
                ],
                selection: 'radioButtonGroup',
                value: raw('value'),
                displayString: raw('displayString'),
            },
        },
        check_box_group: {
            type: "CheckBoxGroup",
            bindings: {
                list: [
                    { value: '', displayString: 'None', },
                    { value: 'D', displayString: 'Debussy, Claude', },
                    { value: 'F', displayString: 'Fauré, Gabriel', },
                    { value: 'R', displayString: 'Ravel, Maurice', },
                    { value: 'S', displayString: 'Saint-Saëns, Camille', },
                ],
                selection: 'checkBoxGroup',
                value: raw('value'),
                displayString: raw('displayString'),
            },
        },
        text_field: {
            type: "TextField",
            bindings: {
                value: 'textFieldValue',
            },
        },
        text: {
            type: "Text",
            bindings: {
                value: 'textValue',
            },
        },
        hidden_field: {
            type: "HiddenField",
            bindings: {
                value: 'hiddenFieldValue',
            },
        },
        pop_up_menu: {
            type: "PopUpMenu",
            bindings: {
                list: [
                    { value: '', displayString: 'None', },
                    { value: 'A', displayString: 'Albeniz, Isaac', },
                    { value: 'F', displayString: 'Falla, Manuel de', },
                    { value: 'G', displayString: 'Granados, Enrique', },
                    { value: 'S', displayString: 'Sor, Fernando', },
                ],
                selection: 'popUpMenu',
                value: raw('value'),
                displayString: raw('displayString'),
            },
        },
        scrolling_list: {
            type: "ScrollingList",
            bindings: {
                list: [
                    { value: '', displayString: 'None', },
                    { value: 'F', displayString: 'Franck, César', },
                    { value: 'H', displayString: 'Haydn, Franz Joseph', },
                    { value: 'R', displayString: 'Reicha, Antonin', },
                    { value: 'S', displayString: 'Sor, Fernando', },
                    { value: 'V', displayString: 'Vieuxtemps, Henri', },
                ],
                selection: 'scrollingList',
                value: raw('value'),
                displayString: raw('displayString'),
            },
        },
        selection: {
            type: 'Selection',
            bindings: {
                list: [
                    { value: '', displayString: 'None', },
                    { value: 'B', displayString: 'Balakirev, Milii', },
                    { value: 'C', displayString: 'Cui, Cesar', },
                    { value: 'G', displayString: 'Glinka, Mikhail', },
                ],
                selectedValues: 'selection',
                value: raw('value'),
                displayString: raw('displayString'),
            },
        },
        submit_button: {
            type: 'SubmitButton',
        },
    };
}

@end
