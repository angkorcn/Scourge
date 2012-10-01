package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.rules.BuildBoardRule;
import net.rezmason.scourge.model.rules.BuildStateRule;
import net.rezmason.scourge.model.rules.BuildPlayersRule;

using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.Pointers;

class RuleTest
{
    var history:StateHistory;

    var state:State;
    var historyState:State;
    var plan:StatePlan;

    public function new() {

    }

    @BeforeClass
    public function beforeClass():Void {
        history = new StateHistory();
        state = new State();
        historyState = new State();
    }

    @AfterClass
    public function afterClass():Void {
        history.wipe();
        historyState.wipe();
        state.wipe();

        history = null;
        historyState = null;
        state = null;
    }

    private function makeState(rules:Array<Rule> = null,  numPlayers:Int = 1, initGrid:String = null, circular:Bool = false):Void {

        history.wipe();
        historyState.wipe();
        state.wipe();

        if (rules == null) rules = [];

        // make state config and generate state
        var buildStateConfig:BuildStateConfig = {firstPlayer:0, history:history, historyState:historyState};
        var buildStateRule:BuildStateRule = new BuildStateRule(buildStateConfig);

        // make player config and generate players
        var buildPlayersCfg:BuildPlayersConfig = {numPlayers:numPlayers, history:history, historyState:historyState};
        var buildPlayersRule:BuildPlayersRule = new BuildPlayersRule(buildPlayersCfg);

        // make board config and generate board
        var buildBoardCfg:BuildBoardConfig = {circular:circular, initGrid:initGrid, history:history, historyState:historyState};
        var buildBoardRule:BuildBoardRule = new BuildBoardRule(buildBoardCfg);

        rules.unshift(buildBoardRule);
        rules.unshift(buildPlayersRule);
        rules.unshift(buildStateRule);

        plan = new StatePlanner().planState(state, rules);
        for (rule in rules) rule.prime(state, plan);
    }

    private function testListLength(expectedLength:Int, first:BoardNode, next:AspectPtr, prev:AspectPtr):Int {
        var count:Int = 0;
        var last:BoardNode = null;

        for (node in first.iterate(state.nodes, next)) {
            count++;
            last = node;
            if (count > expectedLength) break;
        }
        if (expectedLength != count) return expectedLength - count;

        count = 0;
        for (node in last.iterate(state.nodes, prev)) {
            count++;
            if (count > expectedLength) break;
        }

        return expectedLength - count;
    }
}
