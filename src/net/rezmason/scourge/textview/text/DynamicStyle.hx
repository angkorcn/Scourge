package net.rezmason.scourge.textview.text;

class DynamicStyle extends Style {

    var stateStyles:Array<Style>;
    var states:Array<Array<Float>>;

    public function new(?name:String, ?basis:String, ?initValues:Dynamic, ?mouseID:Int):Void {
        stateStyles = [];
        super(name, basis, initValues, mouseID);
    }

    private function connectStates(bases:Map<String, Style>, stateNames:Array<String>):Void {
        if (stateNames.length > 0) {
            for (ike in 0...stateNames.length) {
                var stateStyle:Style = new Style('${name}_$ike');
                if (stateNames[ike] == null || bases[stateNames[ike]] == null) stateStyle.inherit(this);
                else stateStyle.inherit(bases[stateNames[ike]]);
                stateStyle.inherit(bases['']);
                stateStyles.push(stateStyle);
            }
        } else {
            inherit(bases['']);
        }
    }

    private function interpolateGlyphs(state1:Int, state2:Int, ratio:Float):Void {
        if (states == null) return;
        for (ike in 0...states.length) {
            var fieldValues:Array<Float> = states[ike];
            if (fieldValues != null) basics[ike] = fieldValues[state1] * (1 - ratio) + fieldValues[state2] * ratio;
        }
    }

    override public function flatten():Void {

        states = [];
        var hasNoStates:Bool = true;

        for (ike in 0...Style.styleFields.length) {
            var field:String = Style.styleFields[ike];
            var doesFieldChange:Bool = false;
            var fieldValues:Array<Float> = [];
            var firstValue = null;

            if (values[field] == null && stateStyles.length > 0) {
                firstValue = stateStyles[0].values[field];
                for (stateStyle in stateStyles) {
                    if (!doesFieldChange && firstValue != stateStyle.values[field]) doesFieldChange = true;
                    fieldValues.push(stateStyle.values[field]);
                }
            }

            if (doesFieldChange) {
                states[ike] = fieldValues;
                hasNoStates = false;
            } else if (values[field] == null) {
                states[ike] = null;
                values[field] = firstValue;
            }
        }

        if (hasNoStates) states = null;

        super.flatten();
    }
}
