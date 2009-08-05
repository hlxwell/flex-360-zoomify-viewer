package ThePlant
{
	import flash.events.MouseEvent;
	
	import mx.containers.Canvas;
	import mx.controls.*;
	
	import org.openzoom.flash.viewport.constraints.CenterConstraint;
	import org.openzoom.flash.viewport.constraints.CompositeConstraint;
	import org.openzoom.flash.viewport.constraints.ZoomConstraint;
	import org.openzoom.flash.viewport.controllers.*;
	import org.openzoom.flash.viewport.transformers.*;
	import org.openzoom.flex.components.*;

	public class Frames extends Canvas
	{
//	      [Bindable]
//        [Embed(source="../360viewer/mouse/move.png")]
//        private var moveIcon:Class;
//        [Bindable]
//        [Embed(source="../360viewer/mouse/zoom.png")]
//        private var zoomIcon:Class;
//        private var cursorID:int;

		public var variationId:String;
		public var totalFramesCount:int;
		public var showTopBottomButtons:int;

		private var _frames:Array;
		private var _specialFrames:Array;
		private var _currentFrameId:Number;
		private var _currentTmpFrameId:Number;
		private var _startX:Number;
		private var _startY:Number;
		private var _dragFactor:Number;
		private var _isCtrl:Boolean;
		private var _rotateMode:Boolean;
		private var _currentZoom:Number;
		private var _frameOriginalX:Number;
		private var _frameOriginalY:Number;
		private var _notMoving:Boolean;

		public function Frames()
		{
			this.width					= 594;
			this.height					= 285;
			this.totalFramesCount 		= 0;
			this.showTopBottomButtons	= 0;
			this._dragFactor			= 30;
			this.horizontalScrollPolicy	= "off";
			this.verticalScrollPolicy	= "off";
			
			variationId			= "0"
			_isCtrl				= false;
			_rotateMode			= true;
			_notMoving			= true;
			_currentFrameId 	= 1;
			_currentZoom		= 1;
			_frames 			= new Array();
			_specialFrames		= new Array();
			
			this.addEventListener(MouseEvent.CLICK, mcOnClick);
			this.addEventListener(MouseEvent.MOUSE_DOWN, mcOnPress);
			this.addEventListener(MouseEvent.MOUSE_UP, mcOnRelease);
			this.addEventListener(MouseEvent.MOUSE_MOVE, mcOnMouseMove);
			this.addEventListener(MouseEvent.ROLL_OUT, mcOnRollOut);
			this.addEventListener(MouseEvent.ROLL_OVER, mcOnRollOver);
		}

		public function reload():void {
			if(variationId != "0") {				
				_rotateMode			= true;
				_currentFrameId 	= 1;
				_currentZoom		= 1;
				initFrames();
			}
		}
		
		public function reset():void {
			_currentFrameId 	= 1;
			_currentZoom		= 1;
			_rotateMode 		= true;
			this.hideSpecialFrame();
			this.rotateTo(1);
			currentFrame().showAll(true);
		}
		
		// get current frame object
		public function currentFrame():MultiScaleImage {
			if(this._rotateMode) {
				return this._frames[this._currentFrameId];
			} else {
				return this._specialFrames[this._currentFrameId];
			}
		}
		
		// jump to specified frame
		public function rotateTo(index:int):void {
			if(this._rotateMode) {
				// synchronize positions and zoom information to all frames
				synchAllFrame();
				
				for(var i:int = 1; i <= totalFramesCount; i ++) {
					_frames[i].visible = false;
					if( i == index ) {
						_frames[i].visible = true;
					}
				}
			}
		}
		
		public function showSpecialFrame(index:Number):void {
			if (showTopBottomButtons == 1){
				switchMode('special_view');
				_currentFrameId = index;
				_currentZoom = 1;
				
				_specialFrames[1].showAll(true);
				_specialFrames[1].visible = true;
			} else if (showTopBottomButtons == 2){
				switchMode('special_view');
				_currentFrameId = index;
				_currentZoom = 1;
				
				_specialFrames[2].showAll(true);
				_specialFrames[2].visible = true;
			} else if (showTopBottomButtons == 3){
				switchMode('special_view');
				_currentFrameId = index;
				_currentZoom = 1;
				
				for(var i:int = 1; i < 3; i ++) {
					if( i == index ) {					
						_specialFrames[i].showAll(true);
						_specialFrames[i].visible = true;
					} else {
						_specialFrames[i].visible = false;
					}
				}
			}
		}
		
		public function hideSpecialFrame():void {
			if (showTopBottomButtons == 1){
				_specialFrames[1].visible = false;
			} else if (showTopBottomButtons == 2){
				_specialFrames[2].visible = false;
			} else if (showTopBottomButtons == 3){
				for(var i:int = 1; i < 3; i ++) {
					_specialFrames[i].visible = false;
				}
			}
		}
		
		public function leftRotate():void {
			if(this._rotateMode) {
				mcGotoAndStop(-1);
				if(_currentTmpFrameId) {
					_currentFrameId = _currentTmpFrameId;
				}
			}
		}
		
		public function rightRotate():void {
			if(this._rotateMode) {
				mcGotoAndStop(1);
				if(_currentTmpFrameId) {
					_currentFrameId = _currentTmpFrameId;
				}
			}
		}

		public function zoomIn():void {			
			if(_currentZoom < 4) {
				_currentZoom += 0.5;
				currentFrame().zoomTo(_currentZoom);
			}
			
			enableMouseController(true);
		}
		
		public function zoomOut():void {
			_currentZoom = currentFrame().zoom;			 
			if(_currentZoom > 1) {
				_currentZoom -= 0.5;
				
				// keep min value of _currentZoom is 1.
				if(_currentZoom < 1) {
					_currentZoom = 1;
				}
				currentFrame().zoomTo(_currentZoom);
			}
			
			if(_currentZoom == 1) {
				enableMouseController(false);
			}
		}
		
		public function switchMode(mode:String):void {
			if(mode == "rotate") {
				hideSpecialFrame();
				this._rotateMode = true;
			} else {
				rotateTo(0);
				this._rotateMode = false;
			}
			
		}
		
		// private methods ////////////////////////////////////////
		private function initFrames():void {
			this.removeAllChildren();
			// rotate frames
			for(var i:int = 1; i <= totalFramesCount; i ++) {
				_frames[i] = new MultiScaleImage();

				// create constraints
				var compositeConstrains:CompositeConstraint = new CompositeConstraint();
				var zoomConstraint:ZoomConstraint = new ZoomConstraint();
				zoomConstraint.minZoom 	= 1;
				zoomConstraint.maxZoom 	= 4;

				var centerConstraint:CenterConstraint = new CenterConstraint();
				compositeConstrains.constraints = [ zoomConstraint, centerConstraint ];
				
				_frames[i].constraint 	= compositeConstrains;
				_frames[i].width 		= 594;
				_frames[i].height 		= 295;
				_frames[i].transformer 	= new TweenerTransformer();
//				_frames[i].source 		= "file:///Users/michael/Documents/Flex%20Builder%203/360viewer/images/DSC_098" + i.toString() + ".dzi";
				_frames[i].source 		= "/images/product_variations/" + this.variationId + "/360_" + i.toString() + ".dzi";
				if( i!=1 ) {
					_frames[i].visible = false;
				}
				this.addChild(_frames[i]);
			}
			
			if(showTopBottomButtons == 1) {
				addSpecialView(1, 'top');
			} else if(showTopBottomButtons == 2) {
				addSpecialView(2, 'bottom');
			} else if(showTopBottomButtons == 3) {
				// top and bottom views
				var top_bottom:Array = ["top", "bottom"];
				for(var j:int = 1; j < 3; j ++) {
					addSpecialView(j, top_bottom[j-1]);
				}
			}
		}
		
		private function addSpecialView(index:int, viewName:String):void {
			_specialFrames[index] = new MultiScaleImage();
					
			// create constraints
			var compositeConstrains1:CompositeConstraint = new CompositeConstraint();				
			var zoomConstraint1:ZoomConstraint = new ZoomConstraint();
			zoomConstraint1.minZoom 	= 1;
			zoomConstraint1.maxZoom 	= 4;

			var centerConstraint1:CenterConstraint = new CenterConstraint();				
			compositeConstrains1.constraints = [ zoomConstraint1, centerConstraint1 ];
			
			_specialFrames[index].controllers 	= [new MouseController(), new KeyboardController()];
			_specialFrames[index].constraint 	= compositeConstrains1;
			_specialFrames[index].width 		= 594;
			_specialFrames[index].height 		= 295;
			_specialFrames[index].transformer 	= new TweenerTransformer();
//			_specialFrames[index].source 		= "file:///Users/michael/Documents/Flex%20Builder%203/360viewer/images/DSC_098" + viewName + ".dzi";
			_specialFrames[index].source 		= "/images/product_variations/" + this.variationId + "/360_" + viewName + ".dzi";					
			_specialFrames[index].visible = false;
			this.addChild(_specialFrames[index]);
		}
		
		private function synchAllFrame():void {
			for(var i:int = 1; i <= totalFramesCount; i ++) {
				this._frames[i].zoomTo(this._frames[_currentFrameId].zoom,0,0,true);
				this._frames[i].panTo(this._frames[_currentFrameId].viewportX, this._frames[_currentFrameId].viewportY, true);
			}
		}
		
		///// /event handlers //////////////////////////////////
		private function mcOnPress(event:MouseEvent):void {
			_startX = event.stageX;
			_startY = event.stageY;
			_notMoving = true;
			if(currentFrame().zoom > 1.2) {
				_isCtrl = false;
			} else {
				_isCtrl = true;
			}
		}

		private function mcOnRelease(event:MouseEvent):void {
			_isCtrl = false;
			
			if(_currentTmpFrameId && _rotateMode) {
				_currentFrameId = _currentTmpFrameId;
			}
		}
		
		private function mcOnMouseMove(event:MouseEvent):void {
			if (_isCtrl) {
				var frame_d:Number = Math.ceil((event.stageX - _startX) / _dragFactor);
				mcGotoAndStop(frame_d);
				_notMoving = false;
			}
			
			showMouseIcon();
		}
		
		private function mcOnRollOut(event:MouseEvent):void {
			_isCtrl = false;
//			CursorManager.removeCursor(cursorID);
		}
		
		private function mcOnRollOver(event:MouseEvent):void {
			showMouseIcon();
		}		

		private function mcOnClick(event:MouseEvent):void {			
			if(_currentZoom == 1 && _notMoving) {
				_currentZoom += 0.5;
				currentFrame().zoomTo(_currentZoom);
				enableMouseController(true);
			}
		}
		//////////////////////////////////////////////////////////////////
		
		private function showMouseIcon():void {
//			if(currentFrame().zoom > 1) {
//				CursorManager.removeCursor(cursorID);
//				cursorID = CursorManager.setCursor(zoomIcon, 1, -10, -10);
//			} else {
//				CursorManager.removeCursor(cursorID);
//				cursorID = CursorManager.setCursor(moveIcon, 1, -10, -10);
//			}
		}
		
		private function mcGotoAndStop(stepsCount:int):void {
			var frame_final:Number = _currentFrameId + stepsCount;

			while (frame_final > totalFramesCount) {
				frame_final -= totalFramesCount;
			}
			while (frame_final<1) {
				frame_final += totalFramesCount;
			}

			_currentTmpFrameId = frame_final;
			this.rotateTo(frame_final);
		}

		private function enableMouseController(enable:Boolean):void {
			if(enable) {
				for(var i:int = 1; i <= totalFramesCount; i ++) {
					this._frames[i].controllers = [new MouseController()];
				}
			} else {
				for(var j:int = 1; j <= totalFramesCount; j ++) {
					this._frames[j].controllers = [];
				}
			}
		}
	}
}