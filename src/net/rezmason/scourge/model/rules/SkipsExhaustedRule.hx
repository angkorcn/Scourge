package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.IdentityAspect;
import net.rezmason.scourge.model.aspects.PlyAspect;
import net.rezmason.scourge.model.aspects.WinAspect;

using net.rezmason.utils.Pointers;

typedef SkipsExhaustedConfig = {
    var maxSkips:Int;
}

class SkipsExhaustedRule extends Rule {

    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @player(IdentityAspect.PLAYER_ID) var playerID_;
    @player(PlyAspect.NUM_CONSECUTIVE_SKIPS) var numConsecutiveSkips_;
    @state(WinAspect.WINNER) var winner_;

    private var cfg:SkipsExhaustedConfig;

    // This rule discovers whether there is only one remaining player, and makes that player the winner
    public function new(cfg:SkipsExhaustedConfig):Void {
        super();
        this.cfg = cfg;
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {

        var stalemate:Bool = true;

        if (state.aspects[winner_] != Aspect.NULL) {
            stalemate = false;
        } else {
            for (player in eachPlayer()) {
                if (player[numConsecutiveSkips_] < cfg.maxSkips) {
                    stalemate = false;
                    break;
                }
            }
        }

        var largestArea:Int = -1;
        var largestPlayers:Array<Int> = null;

        if (stalemate) {
            for (player in eachPlayer()) {
                var playerID:Int = player[playerID_];
                var totalArea:Int = player[totalArea_];

                if (totalArea > largestArea) largestPlayers = [playerID];
                else if (totalArea == largestArea) largestPlayers.push(playerID);
            }

            state.aspects[winner_] = largestPlayers.pop();
        }
    }
}

