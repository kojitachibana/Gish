/*
 * Gish::Beat Slicer for monome64.
 *
 *
 * Gish is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option ) any later version.
 *
 * Gish is distributed in the hope that it will be useful,
 * but WITHIOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Gish. if not, see <http:/www.gnu.org/licenses/>.
 *
 * => Features
 *    Beat Slice and Sequencer
 *    4 Audio Tracks
 *    Editable parameters:
 *    Plyaback position select, Sample pitch, Reverce playback and Beat repeat
 *
 * => OSC Settings
 *    Prefix: /chuck
 *    Receive port: 8080
 *
 * => How To Run
 *    1.Assign Audio file path
 *    2.Launch Cish.ck(Add Shread button or cmd+) on miniAudicle
 *      (http://audicle.cs.princeton.edu/mini/)
 *    3.Push Enter key.(Enter key is assigned Sequnecer start button.)
 *    4.When you push space key, monome LED params change.
 *    
 * => HID Keyboad assignments
 *    enter: Start/Stop Sequence.
 *    space: monome LED Params Change(sample => pitch => reverce => repeat)
 *    z: Select Track 01
 *    x: Select Track 02
 *    c: Select Track 03
 *    v: Select Track 04
 *    a: BPM-5
 *    s: BPM+5
 *    delete: All LED Off(send osc command "/chuck/clear")
 *
 * => LED Pamams Assignmets
 *
 *    1.Sample plyaback position
 *    When you push the lighting LED(selected sample position), this step is muted.
 *    ---------------------------------------
 *                                       ROW:Position
 *              [0][1][2][3][4][5][6][7] 7
 *              [0][1][2][3][4][5][6][7] 6
 *              [0][1][2][3][4][5][6][7] 5
 *              [0][1][2][3][4][5][6][7] 4
 *              [0][1][2][3][4][5][6][7] 3
 *              [0][1][2][3][4][5][6][7] 2
 *              [0][1][2][3][4][5][6][7] 1
 *              [0][1][2][3][4][5][6][7] 0
 *     COL:Steps 0  1  2  3  4  5  6  7
  *    ---------------------------------------
 *
 *    2.Plyaback Pitch
 *    ---------------------------------------
 *                                        ROW:Pitch
 *              [0][1][2][3][4][5][6][7]  -(no param assigned...)
 *              [0][1][2][3][4][5][6][7]  3
 *              [0][1][2][3][4][5][6][7]  2
 *              [0][1][2][3][4][5][6][7]  1
 *              [0][1][2][3][4][5][6][7]  0
 *              [0][1][2][3][4][5][6][7] -1
 *              [0][1][2][3][4][5][6][7] -2
 *              [0][1][2][3][4][5][6][7] -3
 *     COL:Steps 0  1  2  3  4  5  6  7
 *    ---------------------------------------
 *
 *    3.Reverce Plyaback
 *    ---------------------------------------
 *                                       ROW:Reverce
 *              [0][1][2][3][4][5][6][7] 7
 *              [0][1][2][3][4][5][6][7] 6
 *              [0][1][2][3][4][5][6][7] 5
 *              [0][1][2][3][4][5][6][7] 4
 *              [0][1][2][3][4][5][6][7] 3
 *              [0][1][2][3][4][5][6][7] 2
 *              [0][1][2][3][4][5][6][7] 1
 *              [0][1][2][3][4][5][6][7] 0
 *     COL:Steps 0  1  2  3  4  5  6  7
 *    ---------------------------------------
 *
 *    4.Beat repeat
 *    ---------------------------------------
 *                                       ROW:repeat
 *              [0][1][2][3][4][5][6][7] 7
 *              [0][1][2][3][4][5][6][7] 6
 *              [0][1][2][3][4][5][6][7] 5
 *              [0][1][2][3][4][5][6][7] 4
 *              [0][1][2][3][4][5][6][7] 3
 *              [0][1][2][3][4][5][6][7] 2
 *              [0][1][2][3][4][5][6][7] 1
 *              [0][1][2][3][4][5][6][7] 0
 *     COL:Steps 0  1  2  3  4  5  6  7
 *    ---------------------------------------
 */


string file[4];


//----Audio file assing here.----//
//"xxx.aif" => file[0]; or "xxx.wav" => file[0];
"" => file[0];//truck.01
"" => file[1];//truck.02
"" => file[2];//truck.03
"" => file[3];//truck.04
//
//----Audio file assing here.----//


//---- Sequencer BPM Initial Param.----//
//
70 => float bpm;
//
//---- Sequencer BPM Initial Param.----//


//-------------------------------------------------------------------------------------------//

//Seq&Led Params
"/chuck" => string prefix;//OSC Message prefix
0 => int screen;//screen number(0:sample, 1:pitch, 2:reverce, 3:repeat)
0 => int track;//current screen track number(0~3);
0 => int start;//sequencer staus
0 => int step;//sequencer step

//event
Event startEvent;
Event changeScreen;
	
//Audio modules Paams
SndBuf readBuff[4];
Dyno comp;
0.5 => comp.thresh;
9 => comp.ratio;
Gain master;
1 => master.gain;

//test params
0 => int count;

//Audio modules initialize
for (int i; i<readBuff.size(); i++){
	readBuff[i] => comp => master => dac;
	file[i] => readBuff[i].read;
	readBuff[i].loop(0);
	readBuff[i].rate(0);
}

//Monome Class initialize.
Monome m;
m.init();

//HID Device Class initialize.
HIDDevice d;
d.init();

spork ~ seqnecerStatusListener(startEvent);

while (true) 1::day => now;
me.yield();

//Start/Stop Event Lintener
fun int seqnecerStatusListener(Event startEvent) {
	while (true) {
		startEvent => now;
		
		if (start == 0) 1 => start;
		else 0 => start;
		
		if (start == 1) spork ~seqence() @=> Shred @ s;
		else {
			for (int i; i<readBuff.size(); i++){
				readBuff[i].rate(0);
			}
			d.beatLedLow();
			Machine.remove(s.id());
		}
	}
}

fun void seqence() {
	while(true) {
		if (step%4 == 0) spork ~beat();
		
		m.ledCol(step%8, 255);
		spork ~beatSlice(step%8, 0);
		spork ~beatSlice(step%8, 1);
		spork ~beatSlice(step%8, 2);
		spork ~beatSlice(step%8, 3);
		bpm2Sec(bpm)::second => now;
		
		m.updateScreenCol(step%8);
		
		1 +=> step;
	}
}

fun void beat() {
	d.beatLedHigh();
	bpm2Sec(bpm)::second => now;
	d.beatLedLow();
}

fun float bpm2Sec(float bpm) {
	return (1.0 / (bpm / 60.0)) / 4;
}

fun void beatSlice(int step, int track) {
	if (m.sample[track][step] == -1) {
		0 => readBuff[track].rate;
	}
	else {
		(7 - m.rep[track][step]) => int rep;
		if (rep > 0) {
			for (0 => int i; i<rep; i++) {
				chop(step, track);
				(bpm2Sec(bpm) / rep)::second => now;
			}
		}
		else {
			chop(step, track);
			(bpm2Sec(bpm))::second => now;
		}
	}
}

fun void chop(int step, int track) {
	m.sample[track][step] / 8.0 => float fraction;
	
	((4 - m.pitch[track][step]) * 0.2) => float p;
	if (m.reverce[track][step] == 7) (1 + p) => readBuff[track].rate;
	else ((7 - m.reverce[track][step]) * -0.4 - 1) => readBuff[track].rate;
	
	(readBuff[track].samples() * fraction) $ int => int sample;
	readBuff[track].pos(sample);
}

class Monome {
	OscSend oscSender;
	OscRecv oscReceiver;
	OscEvent oscReceiveEvent;
	
	int x, y, state;
	
	int sample[4][8];//Sample index params
	int pitch[4][8];//pitch params
	int reverce[4][8];//reverce params
	int rep[4][8];//repeat params
	
	int toggle[8];
	1 => toggle[0];
	2 => toggle[1];
	4 => toggle[2];
	8 => toggle[3];
	16 => toggle[4];
	32 => toggle[5];
	64 => toggle[6];
	128 => toggle[7];
	
	int fader[8];
	255 => fader[0];
	254 => fader[1];
	252 => fader[2];
	248 => fader[3];
	240 => fader[4];
	224 => fader[5];
	192 => fader[6];
	128 => fader[7];
	
	int centerd[8];
	31 => centerd[0];
	30 => centerd[1];
	28 => centerd[2];
	24 => centerd[3];
	16 => centerd[4];
	48 => centerd[5];
	112 => centerd[6];
	240 => centerd[7];
	
	//Monome Class Initialize
	fun void init() {
		oscSender.setHost("localhost", 8080);
		8000 => oscReceiver.port;
		oscReceiver.listen();
		
		for (0 => int i; i<4; i++) {
			for (0 => int j; j<8; j++) {
				(7-j) => sample[i][j];
				4 => pitch[i][j];
				7 => reverce[i][j];
				7 => rep[i][j];
			}
		}
		
		//OSC Receive Event initialize
		oscReceiver.event(prefix + "/press", "iii") @=> oscReceiveEvent;
		
		setupPrefix();
		clearAllLed();
		updateScreen();
		
		spork ~ changeScreenListener(changeScreen);
		spork ~pressListener();
	}
	
	//Pressed Monome Buttonpad Listener
	fun void pressListener(){
		while(true){
			oscReceiveEvent => now;
			while (oscReceiveEvent.nextMsg() != 0) {
				oscReceiveEvent.getInt() => x;
				oscReceiveEvent.getInt() => y;
				oscReceiveEvent.getInt() => state;
				
				if (state == 1) {
					if (screen == 0) {
						if (sample[track][x] == y) {
							ledCol(x, 0);
							-1 => sample[track][x];
						}
						else { 
							y => sample[track][x];
						}
					}
					else if (screen == 1 && y > 0) {
						y => pitch[track][x];
					}
					else if (screen == 2) y => reverce[track][x];
					else if (screen == 3) y => rep[track][x];
					
					updateScreenCol(x);
				}
			}
		}
	}
	
	fun void led(int x, int y, int state) {
		oscSender.startMsg(prefix + "/led", "iii");
		x => oscSender.addInt;
		y => oscSender.addInt;
		state => oscSender.addInt;
	}
	
	fun void ledCol(int col, int state) {
		oscSender.startMsg(prefix + "/led_col", "ii");
		col => oscSender.addInt;
		state => oscSender.addInt;
	}
	
	fun void ledRow(int row, int state) {
		oscSender.startMsg(prefix + "/led_row", "ii");
		row => oscSender.addInt;
		state => oscSender.addInt;
	}
	
	fun void clearAllLed() {
		oscSender.startMsg(prefix + "/clear", "i");
		0 => oscSender.addInt;
	}
	
	fun void setupPrefix() {
		oscSender.startMsg("/sys/prefix", "s");
		prefix => oscSender.addString;
	}
	
	//Update Col LEDs
	fun void updateScreenCol(int index) {
		if      (screen == 0) {
			if (sample[track][index] == -1) { 
				ledCol(index, 0);
			}
			else {
				ledCol(index, toggle[sample[track][index]]);
			}
		}
		else if (screen == 1) ledCol(index, centerd[pitch[track][index]]);
		else if (screen == 2) ledCol(index, fader[reverce[track][index]]);
		else if (screen == 3) ledCol(index, fader[rep[track][index]]);
	}
	
	//Update All LEDs
	fun void updateScreen() {
		for (0 => int i; i<8; i++) {
			updateScreenCol(i);
		}
	}
	
	//Change Screen Event Listener
	fun int changeScreenListener(Event changeScreen) {
		while (true) {
			changeScreen => now;
			updateScreen();
		}
	}
}

class HIDDevice {
	Hid hi;
	HidMsg msg;
	
	MAUI_View control_view;
	MAUI_Button screenSelect[4];
	MAUI_Button trackSelect[4];
	MAUI_Slider bpmChange;
	MAUI_LED beatLed;
	
	string buttonLabel[8];
	
	//HID Device and MAUI Class Initialize
	fun void init() {
		0 => int device;
		if (me.args()) me.arg(0) => Std.atoi => device;
		if (!hi.openKeyboard(device)) me.exit();
		//<<< "keyboard '" + hi.name() + "' ready", "" >>>;
		
		control_view.size(430, 240);
		control_view.name("Gish::Beat Repeat Sequnecer");
		
		"BPM" => bpmChange.name;
		bpmChange.display();
		bpmChange.irange(20, 200);
		
		bpmChange.range(20, 200);
		bpmChange.size(380, bpmChange.height());
		bpmChange.position(10, 20);
		bpmChange.value(bpm);
		bpmChange.name("BPM");
		control_view.addElement(bpmChange);
		
		beatLed.size(100, beatLed.height());
		beatLed.position(340, 20);
		beatLed.color(beatLed.green);
		beatLed.unlight();
		control_view.addElement(beatLed);
		
		80 => int y;
		0 => int pos;
		
		for (0 => int i; i < 4; i++) {
			trackSelect[i].toggleType();
			trackSelect[i].size(125, 75);
			trackSelect[i].position(pos, y);
			trackSelect[i].name("Track "+(i+1));
			control_view.addElement(trackSelect[i]);
			
			100 +=> pos;
		}
		
		160 => y;
		0 => pos;
		
		"Sample"  => buttonLabel[0];
		"Pitch"   => buttonLabel[1];
		"Reverce" => buttonLabel[2];
		"Repeat"  => buttonLabel[3];
		
		for (0 => int i; i < 4; i++) {
			screenSelect[i].toggleType();
			screenSelect[i].size(125, 75);
			screenSelect[i].position(pos, y);
			screenSelect[i].name(buttonLabel[i]);
			control_view.addElement(screenSelect[i]);
			
			100 +=> pos;
		}
		
		control_view.display();
		
		toggleScreenSelect(screen);
		toggleTrackSelect(track);
		
		//Start Shread
		spork ~hidListener();
		spork ~changeBPMListener();
		for(0 => int i; i < 4; i++) spork ~ screenSelectListener(i);
		for(0 => int i; i < 4; i++) spork ~ trackSelectListener(i);
	}
	
	//HID Key Input Event Listener
	fun void hidListener(){
		while (true){
			hi => now;
			while (hi.recv( msg )){
				if (msg.isButtonDown()) {
					//<<< "down:", msg.which, "(code)", msg.key, "(usb key)", msg.ascii, "(ascii)" >>>;
					if (msg.ascii == 32) {//Space key(change screen)
						1 +=> screen;
						if (screen == 4) 0 => screen;
						changeScreen.broadcast();
						toggleScreenSelect(screen);
					}
					else if (msg.ascii == 90) {//z key(track01)
						0 => track;
						changeScreen.broadcast();
						toggleTrackSelect(track);
					}
					else if (msg.ascii == 88) {//x key(track02)
						1 => track;
						changeScreen.broadcast();
						toggleTrackSelect(track);
					}
					else if (msg.ascii == 67) {//c key(track03)
						2 => track;
						changeScreen.broadcast();
						toggleTrackSelect(track);
					}
					else if (msg.ascii == 86) {//v key(track04)
						3 => track;
						changeScreen.broadcast();
						toggleTrackSelect(track);
					}
					else if (msg.ascii == 65) {//a key(bpm-5)
						bpmChange.value(bpmChange.value()-5);
						setBPM(bpmChange.value());
					}
					else if (msg.ascii == 83) {//s key(bpm+5)
						bpmChange.value(bpmChange.value()+5);
						setBPM(bpmChange.value());
					}
					else if (msg.ascii == 10) {//enter key(start/stop)
						startEvent.broadcast();
					}
					else if (msg.ascii == 8) {//delete key(led clear)
						m.clearAllLed();
					}
				}
			}
		}
	}
	
	//Screen Select Buttons Event Listener
	function void screenSelectListener(int index) {
		while (true) {
			screenSelect[index] => now;
			
			index => screen;
			changeScreen.broadcast();
			
			for(0 => int i; i < 4; i++) {
				if(i != index){
					//screenSelect[i].state(0);
					screenSelect[i].pushType();
					screenSelect[i].toggleType();
				}
			}
			screenSelect[index].state(1);
			
			screenSelect[index] => now;
		}
	}
	
	//Track Select Buttons Event Listener
	function void trackSelectListener(int index) {
		while (true) {
			trackSelect[index] => now;
			
			index => track;
			changeScreen.broadcast();
			
			for(0 => int i; i < 4; i++) {
				if(i != index){
					//trackSelect[i].state(0);
					trackSelect[i].pushType();
					trackSelect[i].toggleType();
				}
			}
			trackSelect[index].state(1);
			
			trackSelect[index] => now;
		}
	}
	
	//BPM Change Slider Event Listener
	function void changeBPMListener() {
		while(true) {
			bpmChange => now;
			setBPM(bpmChange.value());
		}
	}
	
	//Screen Select Buttons Toggle group
	fun void toggleScreenSelect(int index) {
		for(0 => int i; i < 4; i++) {
			if(i != index){
				screenSelect[i].state(0);
				//screenSelect[i].pushType();
				//screenSelect[i].toggleType();
			}
		}
		
		screenSelect[index].state(1);
	}
	
	//Track Select Buttons Toggle group
	fun void toggleTrackSelect(int index) {
		for(0 => int i; i < 4; i++) {
			if(i != index){
				trackSelect[i].state(0);
				//trackSelect[i].pushType();
				//trackSelect[i].toggleType();
			}
		}
		
		trackSelect[index].state(1);
	}
	
	fun void setBPM(float val) {
		Math.floor(val) => bpm;
	}
	
	fun void beatLedHigh() {
		beatLed.light();
	}
	
	fun void beatLedLow() {
		beatLed.unlight();
	}
}