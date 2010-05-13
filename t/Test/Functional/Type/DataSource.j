@import <WM/ObjectContext.j>
@import <WM/Log.j>
@import "../../../Application.j"
@import "../../../DBTestCase.j"

var application = [WMApplication applicationInstanceWithName:"WMTest"];

@implementation WMDataSourceTest : DBTestCase
{
    WMObjectContext oc;
    id entities;
    id root;
    id trunk;
}

/*
#-----------------------------------------
# Base class for tests that need to build
# up some goop in the DB to test against
#-----------------------------------------
*/

- setUp {
    [WMLog setLogMask:0x0000];
    [super setUp];

    oc = [WMObjectContext new];
    
    var es = []; 
    var ground = [WMTestGround new];
    [ground setColour:"Earthy brown"];
    es[es.length] = ground;

    root = [WMTestRoot new];
    [root setTitle:"Root"];
    [root setGround:ground];
    es[es.length] = root;
    
    trunk = [WMTestTrunk new];
    [trunk setThickness:20];
    es[es.length] = trunk;

    [root setTrunk:trunk];
    
    var globules = [];
    var branches = [];
    
    for (var len = 0; len < 6; len++ ) {
        var branch = [WMTestBranch new];
        [branch setLength:len];
        [branch setLeafCount:(6-len)];
        branches[branches.length] = branch;
        
        var globule = [WMTestGlobule new];
        [globule setName:"Globule-" + len];
        globules[globules.length] = globule;
        
        es = es.concat(branches);
        es = es.concat(globules);
        
        // add it to the trunk
        [trunk addObjectToBranches:branch];
    }
    
    for (var len = 0; len < 6; len++) {
        var b = branches[len];
        var g1 = globules[len];
        var g2 = globules[(len+1)%6];
        
        [b addObjectToGlobules:g1];
        [b addObjectToGlobules:g2];
        
        // i hate that this currently necessary
        [b save];
    }
    
    var isOk = true;
    var count = 0;
    for (var i=0; i < [[trunk branches] count]; i++) {
        var branch = [[trunk branches] objectAtIndex:i];
        if ([[branch globules] count] == 2) { count++; continue };
        isOk = false;
    }
    [self assertTrue:(isOk && count == 6) message:"All branches have 2 globules"];
    
    [root save];
    [self assertNotNull:[root id] message:"Root has an id now"]; 
    [self assertNotNull:[trunk id] message:"Trunk has an id now"]; 
    [self assertNotNull:[ground id] message:"Ground has an id now"]; 

    [self assert:[[ground roots] count] equals:1 message:"Ground has one root"];
    [self assertTrue:([root trunk] && [[root trunk] is:trunk]) message:"Trunk and root connected"];
    [self assert:[[trunk branches] count] equals:6 message:"Trunk has 6 branches"];
    //[WMLog setLogMask:0xffff];eval(_p_setTrace);[WMLog setLogMask:0x0000];
    var isOk = true;
    for (var i=0; i< [[trunk branches] count]; i++) {
        var branch = [[trunk branches] objectAtIndex:i];

        if ([[branch globules] count] == 2) { continue }
        isOk = false;
    }
    [self assertTrue:isOk message:"All branches have 2 globules"];
    
    // check that they are still that way by refetching them
    var rr = [oc entity:"WMTestRoot" withPrimaryKey:[root id]];
    var rtr = [rr trunk];
    var rbs = [rtr branches];
    var isOk = ([rbs count] == 6);

    for (var i=0; i<[rbs count]; i++) {
        var rbr = [rbs objectAtIndex:i];
        var rgs = [rbr globules];
        if ([rgs count] == 2) { continue }
        isOk = false;
    }
    [self assertTrue:isOk message:"All refetched branches have 2 globules"];
    // this just assists with cleanup
    entities = es;
}


- (void)tearDown {
    var found = false;
    for (var i=0; i<[entities count]; i++) {
        var e = [entities objectAtIndex:i];
        [e _deleteSelf];
        var ecdn = [[e entityClassDescription] name];
        var re = [oc entity:ecdn withPrimaryKey:[e id]];
        found = found && re;
    }
    [self assertFalse:found message:"Successfully deleted objects"];
}

- (void)trackEntity:(id)entity { 
    entities = entities || [];
    entities[entities.length] = entity;
}

@end
