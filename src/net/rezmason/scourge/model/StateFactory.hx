package net.rezmason.scourge.model;

import haxe.FastList;

import net.rezmason.scourge.model.GridNode;
import net.rezmason.scourge.model.ModelTypes;
import net.rezmason.scourge.model.aspects.Aspect;

using Lambda;
using Std;
using net.rezmason.scourge.model.GridUtils;
using net.rezmason.utils.IntHashUtils;

class StateFactory {
    public function new():Void {

    }

    public function makeState(cfg:StateConfig):State {
        if (cfg == null) return null;

        var state:State = new State();

        var rules:Array<Rule> = cfg.rules;
        while (rules.has(null)) rules.remove(null);

        // Create and populate the aspect requirement lists
        var stateRequirements:AspectRequirements = new AspectRequirements();
        var playerRequirements:AspectRequirements = new AspectRequirements();
        var boardRequirements:AspectRequirements = new AspectRequirements();

        for (rule in rules) {
            stateRequirements.absorb(rule.listStateAspectRequirements());
            playerRequirements.absorb(rule.listPlayerAspectRequirements());
            boardRequirements.absorb(rule.listBoardAspectRequirements());
        }

        // Populate the game state with aspects, players and nodes
        createAspects(stateRequirements, state.aspects);
        for (ike in 0...cfg.playerGenes.length) {
            var genome:String = cfg.playerGenes[ike];
            var head:BoardNode = cfg.playerHeads[ike];
            state.players.push(makePlayer(genome, head, playerRequirements));
        }

        // Populate each node in the graph with aspects
        for (node in cfg.playerHeads[0].getGraph()) createAspects(boardRequirements, node.value);

        return state;
    }

    inline function makePlayer(genome:String, head:BoardNode, requirements:AspectRequirements):PlayerState {
        var playerState:PlayerState = new PlayerState();
        playerState.genome = genome;
        playerState.head = head;
        createAspects(requirements, playerState.aspects);
        return playerState;
    }

    inline function createAspects(requirements:AspectRequirements, hash:IntHash<Aspect> = null):IntHash<Aspect> {
        if (hash == null) hash = new IntHash<Aspect>();
        for (key in requirements.keys()) if (!hash.exists(key)) hash.set(key, Type.createInstance(requirements.get(key), []));
        return hash;
    }
}