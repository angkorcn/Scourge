package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.Aspect;
import net.rezmason.scourge.model.aspects.TestAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;
import net.rezmason.scourge.model.rules.TestRule;

using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class StateFactoryTest {

    var time:Float;

    @Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace("tick " + time);
    }

    @Test
    public function configTest1():Void {

        var history:StateHistory = new StateHistory();

        // make state config and generate state
        var factory:StateFactory = new StateFactory();
        var rules:Array<Rule> = [null, new TestRule()];
        var state:State = factory.makeState(rules, history);

        // Make sure there's the right aspects on the state

        var stateTestValue_:AspectPtr = state.stateAspectLookup[TestAspect.VALUE.id];
        Assert.isNotNull(history.get(state.aspects.at(stateTestValue_)));

        // Make sure there's the right aspects on each player
        var playerTestValue_:AspectPtr = state.playerAspectLookup[TestAspect.VALUE.id];
        for (ike in 0...state.players.length) {
            Assert.isNotNull(history.get(state.players[ike].at(playerTestValue_)));
        }

        // Make sure there's the right aspects on each node
        var nodeTestValue_:AspectPtr = state.nodeAspectLookup[TestAspect.VALUE.id];

        for (node in state.nodes) {
            Assert.isNotNull(history.get(node.value.at(nodeTestValue_)));
        }
    }
}
