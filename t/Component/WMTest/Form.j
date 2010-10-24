/* --------------------------------------------------------------------
 * WM - Web Framework and ORM heavily influenced by WebObjects & EOF
 * (C) kd 2010
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

@import <WM/Component.j>
@import <WM/PageResource.j>

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
    return [ ]
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
                value: 'value',
                displayString: 'displayString',
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
                value: 'value',
                displayString: 'displayString',
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
                    { value: 'A', displayString: 'Albenix, Isaac', },
                    { value: 'F', displayString: 'Falla, Manuel de', },
                    { value: 'G', displayString: 'Granados, Enrique', },
                    { value: 'S', displayString: 'Sor, Fernando', },
                ],
                selection: 'popUpMenu',
                value: 'value',
                displayString: 'displayString',
            },
        },
        scrolling_list: {
            type: "ScrollingList",
            bindings: {
                list: [
                    { value: '', displayString: 'None', },
                    { value: 'F', displayString: 'Franck, César', },
                    { value: 'V', displayString: 'Vieuxtemps, Henri', },
                ],
                selection: 'scrollingList',
                value: 'value',
                displayString: 'displayString',
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
                selection: 'scrollingList',
                value: 'value',
                displayString: 'displayString',
            },
        },
        submit_button: {
            type: 'SubmitButton',
        },
    };
}

@end
