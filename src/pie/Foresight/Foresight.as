package pie.Foresight
{
	import flash.display.Bitmap;
	import flash.display.MovieClip;
	import flash.events.Event;
	import flash.events.KeyboardEvent;
	import flash.utils.*;
	import flash.events.MouseEvent;
	import flash.sampler.ClassFactory;
	
	/**
	 * ...
	 * @author piepie62
	 */
	public class Foresight extends MovieClip
	{
		public const VERSION:String = "0.0.3";
		public const GAME_VERSION:String = "1.1.2b";
		public const BEZEL_VERSION:String = "0.2.1";
		public const MOD_NAME:String = "Foresight";
		
		internal var bezel:Object;
		internal var gameObjects:Object;
		internal var logger:Object;
		
		// Game object shortcuts
		internal var core:Object;/*IngameCore*/
		internal var cnt:Object;/*CntIngame*/
		internal var GV:Object;/*GV*/
		internal var SB:Object;/*SB*/
		internal var prefs:Object;/*Prefs*/
		
		private static var keycodes:Class;
		private static var g1gem:Object;
		private static var lantern:Object;
		
		private var placingType:int;
		
		private var images:Array;
		private var ranges:Array;
		private var cursorImage:MovieClip;
		private var cursorRange:MovieClip;
		private var checkCore:Boolean;
		
		public function Foresight() 
		{
			super();
		}
		
		public function bind(modLoader:Object, gameObjects:Object): Foresight
		{
			this.bezel = modLoader;
			this.logger = modLoader.getLogger("Foresight");
			
			this.gameObjects = gameObjects;
			this.core = gameObjects.GV.ingameCore;
			this.cnt = gameObjects.GV.main.cntScreens.cntIngame;
			this.SB = gameObjects.SB;
			this.GV = gameObjects.GV;
			this.prefs = gameObjects.prefs;

			var rangeimage:Class = getDefinitionByName(getQualifiedClassName(this.cnt.mcRange)) as Class;
			
			this.placingType = -1;
			this.images = new Array();
			this.ranges = new Array();
			for (var x:int = 0; x < 60; x++)
			{
				this.images.push(new Array());
				this.ranges.push(new Array());
				for (var y:int = 0; y < 38; y++)
				{
					this.ranges[x].push(new rangeimage());
					this.ranges[x][y].visible = false;
					this.ranges[x][y].circle.x = x * 28 + 50;
					this.ranges[x][y].circle.y = y * 28 + 4;
					this.ranges[x][y].circle.visible = true;
					this.ranges[x][y].mcMask.width = 1680;
					this.ranges[x][y].mcMask.height = 1064;
					this.ranges[x][y].shrineLine0.visible = false;
					this.ranges[x][y].shrineLine1.visible = false;
					this.ranges[x][y].shrineLine2.visible = false;
					this.ranges[x][y].shrineLine3.visible = false;
					this.ranges[x][y].shrineLine4.visible = false;
					this.ranges[x][y].shrineLine5.visible = false;
					this.ranges[x][y].shrineLine6.visible = false;
					this.ranges[x][y].shrineLine7.visible = false;
					this.ranges[x][y].circleEnh.visible = false;
					
					this.images[x].push(new MovieClip());
					this.images[x][y].x = x * 28 + 46;
					this.images[x][y].y = y * 28 + 4;
					this.images[x][y].visible = true;
				}
			}
			this.cursorRange = new rangeimage();
			this.cursorRange.visible = false;
			this.cursorRange.circle.visible = true;
			this.cursorRange.mcMask.width = 1680;
			this.cursorRange.mcMask.height = 1064;
			this.cursorRange.shrineLine0.visible = false;
			this.cursorRange.shrineLine1.visible = false;
			this.cursorRange.shrineLine2.visible = false;
			this.cursorRange.shrineLine3.visible = false;
			this.cursorRange.shrineLine4.visible = false;
			this.cursorRange.shrineLine5.visible = false;
			this.cursorRange.shrineLine6.visible = false;
			this.cursorRange.shrineLine7.visible = false;
			this.cursorRange.circleEnh.visible = false;

			this.cursorImage = new MovieClip();
			this.cursorImage.visible = false;
			
			keycodes = getDefinitionByName("com.giab.common.constants.KeyCode") as Class;
			
			installEventHooks(modLoader);
			
			logger.log("bind", "Foresight loaded");
			
			return this;
		}
		
		public function installEventHooks(modLoader:Object): void
		{
			bezel.addEventListener("ingameClickOnScene", clickOnSceneHook);
			bezel.addEventListener("ingameRightClickOnScene", rightClickOnSceneHook);
			bezel.addEventListener("ingameKeyDown", keyDownHook);
			bezel.addEventListener("ingameNewScene", sceneLoadHook);
			GV.main.addEventListener("enterFrame", frameHook);
		}
		
		public function unload(): void
		{
			bezel.removeEventListener("ingameClickOnScene", clickOnSceneHook);
			bezel.removeEventListener("ingameRightClickOnScene", rightClickOnSceneHook);
			bezel.removeEventListener("ingameKeyDown", keyDownHook);
			bezel.removeEventListener("ingameNewScene", sceneLoadHook);
			GV.main.removeEventListener("enterFrame", frameHook);
			
			var hud:Object = core.cnt.cntRetinaHud;
			for (var x:int = 0; x < 60; x++)
			{
				for (var y:int = 0; y < 38; y++)
				{
					if (hud.contains(images[x][y]))
					{
						hud.removeChild(images[x][y]);
					}
				}
			}
			if (hud.contains(cursorImage))
			{
				hud.removeChild(cursorImage);
			}
		}
		
		public function clickOnSceneHook(e:Object): void
		{
			var event:MouseEvent = e.eventArgs.event;
			if (placingType != -1)
			{
				var x:int = buildX(GV.main.mouseX);
				var y:int = buildY(GV.main.mouseY);
				
				if (x >= 0 && y >= 0)
				{
					images[x][y].removeChildren();
					var img:* = createImageFor(placingType);
					img.visible = true;
					images[x][y].addChild(img);
					setRangeFor(ranges[x][y], x, y, placingType);
					logger.log("setRangeFor", "Radius " + ranges[x][y].circle.height / 2);
					ranges[x][y].visible = true;
				}
				else
				{
					placingType = -1;
				}
				e.eventArgs.continueDefault = false;
			}
		}
		
		public function rightClickOnSceneHook(e:Object): void
		{
			if (placingType != -1)
			{
				cursorImage.removeChildren();
				cursorRange.visible = false;
				cursorImage.visible = false;
				core.cnt.cntRetinaHud.removeChild(core.cnt.bmpTowerPlaceAvailMap);
				core.cnt.cntRetinaHud.removeChild(core.cnt.bmpNoPlaceBeaconAvailMap);
				placingType = -1;
			}
			else
			{
				var x:int = buildX(GV.main.mouseX);
				var y:int = buildY(GV.main.mouseY);
				for each (var xMod:int in [ -1, 0])
				{
					for each (var yMod:int in [ -1, 0])
					{
						// If it's valid and not a wall, or a wall and in the same tile
						if ((xMod == 0 && yMod == 0) ||
							(x + xMod >= 0 && x + xMod < 60 && y + yMod >= 0 && y + yMod < 38
							 && images[x + xMod][y + yMod].numChildren != 0 &&
							 !(images[x + xMod][y + yMod].getChildAt(0) is (getDefinitionByName(getQualifiedClassName(core.cnt.mcBuildHelperWallLine)) as Class))))
						{
							images[x + xMod][y + yMod].removeChildren();
							ranges[x + xMod][y + yMod].visible = false;
						}
					}
				}
			}
		}
		
		public function keyDownHook(e:Object): void
		{
			var event:KeyboardEvent = e.eventArgs.event;
			var type:int = typeFromKeycode(event.keyCode);
			if (event.ctrlKey)
			{
				if (type != -1 && placingType != type)
				{
					cursorImage.removeChildren();
					e.eventArgs.continueDefault = false;
					this.placingType = type;
					cursorImage.addChild(createImageFor(placingType));
					cursorImage.visible = true;
					cursorRange.visible = true;
					core.cnt.cntRetinaHud.addChild(cursorRange);
					core.cnt.cntRetinaHud.addChild(core.cnt.bmpTowerPlaceAvailMap);
					core.cnt.cntRetinaHud.addChild(core.cnt.bmpNoPlaceBeaconAvailMap);
				}
				else if (type != -1 && placingType == type)
				{
					e.eventArgs.continueDefault = false;
					cursorImage.removeChildren();
					cursorRange.visible = false;
					cursorImage.visible = false;
					this.placingType = -1;
					core.cnt.cntRetinaHud.removeChild(core.cnt.bmpTowerPlaceAvailMap);
					core.cnt.cntRetinaHud.removeChild(core.cnt.bmpNoPlaceBeaconAvailMap);
				}
			}
			else
			{
				if (type != -1 && placingType != -1)
				{
					e.eventArgs.continueDefault = false;
				}
			}
		}
		
		public function frameHook(event:Object): void
		{
			var hud:Object = core.cnt.cntRetinaHud;
				
			var x:int = buildX(GV.main.mouseX);
			var y:int = buildY(GV.main.mouseY);
			
			setRangeFor(cursorRange, x, y, placingType);
			cursorImage.x = x * 28 + 46;
			cursorImage.y = y * 28 + 4;

			for (x = 0; x < 60; x++)
			{
				for (y = 0; y < 38; y++)
				{
					if (core.buildingAreaMatrix != null && core.buildingAreaMatrix[y] != null && core.buildingAreaMatrix[y][x] != null)
					{
						if (core.buildingAreaMatrix[y][x] is (getDefinitionByName("com.giab.games.gcfw.entity.Wall") as Class))
						{
							if (this.images[x][y].numChildren > 0 && this.images[x][y].getChildAt(0) is (getDefinitionByName(getQualifiedClassName(core.cnt.mcBuildHelperWallLine)) as Class))
							{
								this.images[x][y].removeChildren();
								this.ranges[x][y].visible = false;
							}
						}
						else
						{							
							this.images[x][y].removeChildren();
							this.ranges[x][y].visible = false;
						}
					}
				}
			}
		}
		
		public function sceneLoadHook(e:Object): void
		{
			ensureLoadedImages();
			clearImages();
			this.placingType = -1;
			g1gem = GV.ingameCreator.createGem(1, 0, false, false);
			lantern = new (getDefinitionByName("com.giab.games.gcfw.entity.Lantern") as Class)(0,0);
			g1gem.containingBuilding = lantern;
		}
		
		private function clearImages(): void
		{
			var hud:Object = core.cnt.cntRetinaHud;

			for (var x:int = 0; x < 60; x++)
			{
				for (var y:int = 0; y < 38; y++)
				{
					images[x][y].removeChildren();
					ranges[x][y].visible = false;
				}
			}
		}
		
		private static function typeFromKeycode(code:uint): int
		{
			switch (code)
			{
				// Tower
				case keycodes.T:
					return 0;
				// Wall
				case keycodes.W:
					return 1;
				// Trap
				case keycodes.R:
					return 2;
				// Lantern
				case keycodes.L:
					return 3;
				// Amplifier
				case keycodes.A:
					return 4;
				// Pylons
				case keycodes.P:
					return 5;
			}
			return -1;
		}
		
		private static function buildX(x:int): int
		{
			var ret:int = x - 50;
			if (ret >= 0 && ret / 28 < 60)
			{
				return Math.floor(ret / 28);
			}
			else
			{
				return -1;
			}
		}
		
		private static function buildY(y:int): int
		{
			var ret:int = y - 8;
			if (ret >= 0 && ret / 28 < 60)
			{
				return Math.floor(ret / 28);
			}
			else
			{
				return -1;
			}
		}
		
		private function createImageFor(type:int): *
		{
			var ret:Object = null;
			switch (type)
			{
				case 0:
					ret = new Bitmap(core.cnt.bmpBuildHelperTower.bitmapData);
					break;
				case 1:
					ret = new (getDefinitionByName(getQualifiedClassName(core.cnt.mcBuildHelperWallLine)))();
					ret.gotoAndStop(1);
					ret.x = 4;
					ret.y = 4;
					break;
				case 2:
					ret = new Bitmap(core.cnt.bmpBuildHelperTrap.bitmapData);
					ret.x = 8;
					ret.y = 8;
					break;
				case 3:
					ret = new Bitmap(core.cnt.bmpBuildHelperLantern.bitmapData);
					break;
				case 4:
					ret = new Bitmap(core.cnt.bmpBuildHelperAmp.bitmapData);
					break;
				case 5:
					ret = new Bitmap(core.cnt.bmpBuildHelperPylon.bitmapData);
					break;
			}
			return ret;
		}
		
		private function setRangeFor(range:Object, x:int, y:int, type:int): void
		{
			if (type == -1 || type == 1 || type == 2 || type == 4)
			{
				range.circle.visible = false;
				return;
			}

			range.circle.x = x * 28 + 78;
			range.circle.y = y * 28 + 36;
			range.circle.visible = true;
			
			var radius:Number;
			switch (type)
			{
				case 0:
					g1gem.isInLantern = false;
					g1gem.isInTower = true;
					g1gem.recalculateSds(true);
					radius = g1gem.sd5_EnhancedOrTrapOrLantern.range.g();
					break;
				case 3:
					g1gem.isInLantern = true;
					g1gem.isInTower = false;
					g1gem.recalculateSds(true);
					radius = g1gem.containingBuilding.range;
					break;
				case 5:
					radius = 28 * 10 * (1 + GV.ingameCore.skillEffectiveValues[20][0].g());
					break;
			}
			
			range.circle.width = range.circle.height = radius * 2;
		}
		
		private function ensureLoadedImages(): void
		{
			if (!core.cnt.cntRetinaHud.contains(this.images[0][0]))
			{
				for (var x:int = 0; x < 60; x++)
				{
					for (var y:int = 0; y < 38; y++)
					{
						core.cnt.cntRetinaHud.addChild(this.images[x][y]);
						core.cnt.cntRetinaHud.addChild(this.ranges[x][y]);
					}
				}
			}
			
			core.cnt.cntRetinaHud.addChild(cursorImage);
			core.cnt.cntRetinaHud.addChild(cursorRange);
		}
	}
	
}
