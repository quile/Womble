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
@import "../WMModel.j"

@implementation WMDefaultModel : WMModel {

/*
   sub entityNamespace {
       my ($self) = @_;
       return WM::Application->defaultApplication()->configurationValueForKey("DEFAULT_ENTITY_ROOT");
   }
*/

+ entityRoot {
    [WMLog error:"You must subclass entityRoot and specify the path to your entity directory"];
    OS.exit(1);
}

/* this populates the model entries for entities that are
   not mentioned in the model that was loaded from the .pmodel file
*/
- populateModel {
    /*
    var entityDir = [self entityRoot]
                || die "No entity root defined";

    WMLog.debug("Seeking entities in entityDir");
    var entities = [];
    opendir(DIR, entityDir) || die "Can't opendir entityDir: $!";
    var names = grep { /^[^ + ]/ && /\ + pm$/ } readdir(DIR);
    closedir DIR;

    var ecdClass = [self entityClassDescriptionClassName];
    foreach var name (names) {
        name =~ s/\ + pm//g;
        WMLog.debug(" + .. name . + .");

        var fqn = self.NAMESPACE->{ENTITY} + "::name";
        WMLog.debug(": fqn");
        eval "use fqn;";
        if ($@) {
            WMLog.error($@);
            next;
        }
        if (exists self.ENTITIES->{name}) {
            WMLog.debug("Skipping name, it already exists in the .pmodel");
            next;
        }

        unless ([fqn isa:"WMEntityPersistent"]("WMEntityPersistent")) {
            WMLog.warning("Skipping name because it's a transient entity");
            next;
        }

        unless ([fqn can:"Model"]("Model")) {
            WMLog.warning("fqn is not enhanced with Model-Fu");
            next;
        }

        var m = [fqn Model];

        self.ENTITIES->{name} = [fqn __modelEntryOfClassFromArray:ecdClass, m](ecdClass, m);
    }
    */
}

@end
