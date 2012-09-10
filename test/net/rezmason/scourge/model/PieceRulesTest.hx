package net.rezmason.scourge.model;

import massive.munit.Assert;

import net.rezmason.scourge.model.rules.DropPieceRule;
import net.rezmason.scourge.model.rules.TestPieceRule;

class PieceRulesTest extends RuleTest
{
    private static var PIECE_SIZE:Int = 4;

	@Before
    public function setup():Void {
        time = massive.munit.util.Timer.stamp();
    }

    @After
    public function tearDown():Void {
        time = massive.munit.util.Timer.stamp() - time;
        trace("tick " + time);
    }

    // An L/J block has nine neighbor cells.
    // Reflection allowed   rotation allowed    option count
    // N                    N                   9
    // Y                    N                   18
    // N                    Y                   36
    // Y                    Y                   72

	@Test
	public function placePieceRuleTest1():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {overlapSelf:false, allowFlipping:true, allowRotating:true};
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        state = makeState(TestBoards.emptyPetri, 1, [testPieceRule, dropRule]);

        dropRule.update();
        var options:Array<DropPieceOption> = cast dropRule.options;

        Assert.areEqual(72, options.length);

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        //trace(BoardUtils.spitBoard(state));
        dropRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
	}

    @Test
    public function placePieceRuleTest2():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {overlapSelf:false, allowFlipping:false, allowRotating:true};
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        state = makeState(TestBoards.emptyPetri, 1, [testPieceRule, dropRule]);

        dropRule.update();
        var options:Array<DropPieceOption> = cast dropRule.options;

        Assert.areEqual(36, options.length);

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        //trace(BoardUtils.spitBoard(state));
        dropRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceRuleTest3():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {overlapSelf:false, allowFlipping:true, allowRotating:false};
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        state = makeState(TestBoards.emptyPetri, 1, [testPieceRule, dropRule]);

        dropRule.update();
        var options:Array<DropPieceOption> = cast dropRule.options;

        Assert.areEqual(18, options.length);

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        //trace(BoardUtils.spitBoard(state));
        dropRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceRuleTest4():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {overlapSelf:false, allowFlipping:false, allowRotating:false};
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        state = makeState(TestBoards.emptyPetri, 1, [testPieceRule, dropRule]);

        dropRule.update();
        var options:Array<DropPieceOption> = cast dropRule.options;

        Assert.areEqual(9, options.length);

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        //trace(BoardUtils.spitBoard(state));
        dropRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }

    @Test
    public function placePieceRuleTest5():Void {

        var testPieceCfg:TestPieceConfig = {
            pieceID:Pieces.getPieceIdBySizeAndIndex(PIECE_SIZE, 1), // "L/J block"
            reflection:0,
            rotation:0,
        };
        var testPieceRule:TestPieceRule = new TestPieceRule(testPieceCfg);

        var dropConfig:DropPieceConfig = {overlapSelf:true, allowFlipping:false, allowRotating:false};
        var dropRule:DropPieceRule = new DropPieceRule(dropConfig);
        state = makeState(TestBoards.emptyPetri, 1, [testPieceRule, dropRule]);

        dropRule.update();
        var options:Array<DropPieceOption> = cast dropRule.options;

        Assert.areEqual(9 + 4, options.length);

        var numCells:Int = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1, numCells); // 1 cell for player 0

        //trace(BoardUtils.spitBoard(state));
        dropRule.chooseOption(0);
        //trace(BoardUtils.spitBoard(state));

        numCells = ~/([^0])/g.replace(BoardUtils.spitBoard(state), "").length;
        Assert.areEqual(1 + PIECE_SIZE, numCells); // 5 cells for player 0
    }
}