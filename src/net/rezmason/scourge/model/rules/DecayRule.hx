package net.rezmason.scourge.model.rules;

import net.rezmason.ropes.Aspect;
import net.rezmason.ropes.Types;
import net.rezmason.ropes.Rule;
import net.rezmason.scourge.model.aspects.BodyAspect;
import net.rezmason.scourge.model.aspects.FreshnessAspect;
import net.rezmason.scourge.model.aspects.IdentityAspect;
import net.rezmason.scourge.model.aspects.OwnershipAspect;

using Lambda;

using net.rezmason.ropes.GridUtils;
using net.rezmason.scourge.model.BoardUtils;
using net.rezmason.utils.Pointers;

typedef DecayConfig = {
    var orthoOnly:Bool;
}

class DecayRule extends Rule {

    @node(BodyAspect.BODY_NEXT) var bodyNext_;
    @node(BodyAspect.BODY_PREV) var bodyPrev_;
    @node(IdentityAspect.NODE_ID) var nodeID_;
    @node(FreshnessAspect.FRESHNESS) var freshness_;
    @node(OwnershipAspect.IS_FILLED) var isFilled_;
    @node(OwnershipAspect.OCCUPIER) var occupier_;
    @player(BodyAspect.BODY_FIRST) var bodyFirst_;
    @player(BodyAspect.TOTAL_AREA) var totalArea_;
    @player(BodyAspect.HEAD) var head_;
    @state(FreshnessAspect.MAX_FRESHNESS) var maxFreshness_;

    private var cfg:DecayConfig;

    public function new(cfg:DecayConfig):Void {
        super();
        this.cfg = cfg;
        moves.push({id:0});
    }

    override private function _chooseMove(choice:Int):Void {

        var maxFreshness:Int = state.aspects[maxFreshness_] + 1;

        // Grab all the player heads

        var heads:Array<BoardNode> = [];
        for (player in eachPlayer()) {
            var headIndex:Int = player[head_];
            if (headIndex != Aspect.NULL) heads.push(getNode(headIndex));
        }

        // Use the heads as starting points for a flood fill of connected living cells
        var livingBodyNeighbors:Array<BoardNode> = heads.expandGraph(cfg.orthoOnly, isLivingBodyNeighbor);

        // Remove cells from player bodies
        for (player in eachPlayer()) {

            var totalArea:Int = 0;

            var bodyFirst:Int = player[bodyFirst_];
            if (bodyFirst != Aspect.NULL) {
                for (node in getNode(bodyFirst).iterate(state.nodes, bodyNext_)) {
                    if (!livingBodyNeighbors.has(node)) bodyFirst = killCell(node, maxFreshness, bodyFirst);
                    else totalArea++;
                }
            }

            player[bodyFirst_] = bodyFirst;
            player[totalArea_] = totalArea;
        }

        state.aspects[maxFreshness_] = maxFreshness;
    }

    function isLivingBodyNeighbor(me:AspectSet, you:AspectSet):Bool {
        if (me[isFilled_] == Aspect.FALSE) return false;
        return me[occupier_] == you[occupier_];
    }

    function killCell(node:BoardNode, maxFreshness:Int, firstIndex:Int):Int {
        node.value[isFilled_] = Aspect.FALSE;
        node.value[occupier_] = Aspect.NULL;
        node.value[freshness_] = maxFreshness;

        var nextNode:BoardNode = node.removeNode(state.nodes, bodyNext_, bodyPrev_);
        if (firstIndex == node.value[nodeID_]) {
            firstIndex = (nextNode == null) ? Aspect.NULL : nextNode.value[nodeID_];
        }
        return firstIndex;
    }
}

