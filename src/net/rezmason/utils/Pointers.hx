package net.rezmason.utils;

abstract Ptr<T>(#if USE_POINTERS { i:Null<Int>, t:Null<T>, p:Int } #else Int #end) {

    @:allow(net.rezmason.utils) inline function new(i:Int, p:PtrKey) {
        this = #if USE_POINTERS {i:i, t:null, p:p.i()} #else i #end ;
    }

    @:allow(net.rezmason.utils) inline function i():Int return #if USE_POINTERS this.i #else this #end;
    @:allow(net.rezmason.utils) inline function p():Int return #if USE_POINTERS this.p #else 0 #end;

    public inline function isLocked():Bool return #if USE_POINTERS Locker.locks[this.p] #else false #end ;
    public inline static function intToPointer<T>(i:Int, p:PtrKey):Ptr<T> return new Ptr(i, p);
    public inline function toInt():Int return #if USE_POINTERS this.i #else this #end ;
}

abstract PtrSet<T>(Array<T>) {

    public inline function new(a:Array<T> = null) this = (a == null) ? [] : a.copy();
    public inline function wipe():Void this.splice(0, this.length);
    public inline function copy():PtrSet<T> return cast this.copy();
    public inline function copyTo(dest:PtrSet<T>, offset:Int = 0):Void {
        for (ike in 0...this.length) dest.write(ike + offset, this[ike]);
    }
    public inline function map<U>(mapFunc:T->U):PtrSet<U> return cast this.map(mapFunc);
    public inline function mapTo<U>(mapFunc:T->U, dest:PtrSet<U>, offset:Int = 0):Void {
        for (ike in 0...this.length) dest.write(ike + offset, mapFunc(this[ike]));
    }

    inline function write(index:Int, value:T):T return this[index] = value;

    @:arrayAccess inline function ptrAccess(p:Ptr<T>):T {
        #if USE_POINTERS if (p == null) throw 'Null pointer'; return this[p.i()];
        #else return this[p.toInt()];
        #end
    }

    @:arrayAccess inline function ptrWrite(p:Ptr<T>, v:T):T {
        #if USE_POINTERS
            if (p == null) throw 'Null pointer';
            if (p.isLocked()) throw 'Pointer is locked';
            return this[p.i()] = v;
        #else return this[p.toInt()] = v;
        #end
    }

    @:allow(net.rezmason.utils) inline function length():Int return this.length;

    public inline function ptr(i:Int, k:PtrKey):Ptr<T> return new Ptr(i, k);
    public inline function ptrs(k:PtrKey):PtrIterator<T> return new PtrIterator(cast this, k);
}

abstract PtrKey({i:Int}) {
    public inline function new() this = {i:Locker.ids++};
    @:allow(net.rezmason.utils) inline function i():Int return this.i;
    public inline function lock():Void { #if USE_POINTERS Locker.locks[this.i] = true; #end }
    public inline function unlock():Void { #if USE_POINTERS Locker.locks[this.i] = false; #end }
}

class Locker {
    @:allow(net.rezmason.utils) static var ids:Int = 0;
    #if USE_POINTERS @:allow(net.rezmason.utils) static var locks:Array<Bool> = []; #end
}

class PtrIterator<T> {

    var a:PtrSet<T>;
    var k:PtrKey;
    var itr:Int;

    public function new(a:PtrSet<T>, k:PtrKey):Void {
        this.a = a;
        this.k = k;
        itr = 0;
    }

    public function hasNext():Bool return itr < a.length();
    public function next():Ptr<T> return a.ptr(itr++, k);

}
