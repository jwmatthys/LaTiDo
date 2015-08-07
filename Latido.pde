import javax.crypto.Cipher; //<>//
import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;
import java.io.File;
import java.io.IOException;
import java.awt.event.ComponentAdapter;
import java.awt.event.ComponentEvent;
import java.awt.Image;
import static javax.swing.JOptionPane.*;
import de.bezier.guido.*;
import controlP5.*;
import oscP5.*;
import netP5.*;

final float SIDEBAR_WIDTH = 70;
final float TOPBAR_HEIGHT = 70;
int PADDING;
final int TEMPO_LOW = 40;
final int TEMPO_HIGH = 280;
int tempoVal = 60;
int metroOff = 0; // updates frame to deactivate metro toggle
boolean practiceMode = false;

OscP5 oscP5tcpClient;
OscP5 oscP5;
NetAddress latidoPD;

Process pd;

ControlP5 gui;
Group group;
CheckBox metro;

ShowMusic music;
Scorecard scorecard;
MelodyLibraryXML library;
UserProgress userProgress;
String libName;
String savePath;
boolean saving;
Splash splash;
ProgressGraph tree;
Label treeLabel;

void setup()
{
  String p = dataPath("");
  try {
    pd = new ProcessBuilder(p+"/pdbin/bin/pd", "-nogui", "-noprefs", "-r", "44100", p+"/pd/latido.pd").start();
  } 
  catch (Exception e) {
    showMessageDialog(null, "Can't open Pd Audio Engine", "Alert", ERROR_MESSAGE);
  }
  oscP5 = new OscP5 (this, 12000);
  latidoPD = new NetAddress("127.0.0.1", 12001);

  size(1024, 560);
  setupFrame();
  smooth();
  PADDING = width/20;

  Interactive.make(this);

  library = new MelodyLibraryXML();
  music = new ShowMusic();
  libName = library.load("eyes_and_ears");
  music.load(library.getImage());
  music.setText(library.getText());

  userProgress = new UserProgress(System.getProperty("user.name"), libName);
  userProgress.updateInfo(library.currentLine, library.getName());
  savePath = "";
  saving = false;

  gui = new ControlP5(this);
  createGui();

  scorecard = new Scorecard (SIDEBAR_WIDTH + 2*PADDING, TOPBAR_HEIGHT+PADDING, width-SIDEBAR_WIDTH-4*PADDING, height-TOPBAR_HEIGHT-4*PADDING);

  //tree = new ProgressGraph(0, 80, 70, 81);
  //treeLabel = new Label(5, 170, "0 Stars", 11);
  //tree.setMaxScore(library.numMelodies*5);
  splash = new Splash();

  oscP5.plug(this, "micPD", "/mic");
  oscP5.plug(this, "tempoPD", "/tempo");
  oscP5.plug(this, "metroPD", "/metro");
  oscP5.plug(this, "metroStatePD", "/metrostate");
  oscP5.plug(this, "scorePD", "/score");
  oscP5.plug(this, "watchdogPD", "/watchdog");
}

void stop()
{
  pd.destroy();
  OscMessage myMessage = new OscMessage("/latido/quit");
  myMessage.add(1);
  oscP5.send(myMessage, latidoPD);
}

public void updateResize()
{
  group.setPosition(width-230, 20);
  gui.getController("websiteLink").setPosition(width-80, height-30);
}

void createGui()
{
  Group group = gui.addGroup("options")
    .setLabel ("User and Library Options")
      .setPosition(width-230, 30)
        .setSize(220, 300)
          .setBarHeight(20)
            .setBackgroundColor(color(255, 250))
              .close();

  group.getCaptionLabel()
    .align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addButton("playButton")
    .setLabel("Play")
      .setPosition(10, 10)
        .setSize(50, 50).
          getCaptionLabel()
          .align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addButton("stopButton")
    .setLabel("Stop")
      .setPosition(70, 10)
        .setSize(50, 50).
          getCaptionLabel()
          .align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addButton("pitchButton")
    .setLabel("Pitch")
      .setPosition(130, 10)
        .setSize(50, 50).
          getCaptionLabel()
          .align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addButton("playbackButton")
    .setLabel("PlayBack")
      .setPosition(190, 10)
        .setSize(50, 50).
          getCaptionLabel()
          .align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addButton("nextButton")
    .setLabel("Next")
      .setPosition((width/2)+35, 10)
        .setSize(50, 50)
          .getCaptionLabel()
            .align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addButton("previousButton")
    .setLabel("Previous")
      .setPosition((width/2)-85, 10)
        .setSize(50, 50)
          .getCaptionLabel()
            .align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addButton("redoButton")
    .setLabel("Redo")
      .setPosition((width/2)-25, 10)
        .setSize(50, 50).
          getCaptionLabel()
          .align(ControlP5.CENTER, ControlP5.CENTER);


  gui.addButton("websiteLink")
    .setLabel("Find a bug?")
      .setPosition(0, height-20)
        .setSize(70, 20)
          .getCaptionLabel()
            .align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addButton("loadButton")
    .setLabel("Load user progress file")
      .setPosition(10, 10)
        .setSize(200, 50)
          .setGroup(group)
            .getCaptionLabel()
              .align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addButton("saveButton")
    .setLabel("Save user progress file")
      .setPosition(10, 70)
        .setSize(200, 50)
          .setGroup(group)
            .getCaptionLabel()
              .align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addButton("libraryButton")
    .setLabel("Load new Latido module")
      .setPosition(10, 130)
        .setSize(200, 50)
          .setGroup(group)
            .getCaptionLabel()
              .align(ControlP5.CENTER, ControlP5.CENTER);

  gui.addTextlabel("practiceLabel")
    .setText("PRACTICE MODE OFF")
      .setPosition(112, 196)
        .setColor(color(0))
          .setGroup(group);

  gui.addToggle("practiceToggle")
    .setLabel("Switch on/off Practice Mode")
      .setPosition(10, 190)
        .setSize(100, 20)
          .setValue(true)
            .setMode(ControlP5.SWITCH)
              .setGroup(group)
                .getCaptionLabel()
                  .setColor(color(0))
                    ;

  setLock(gui.getController("playButton"), true);
  setLock(gui.getController("stopButton"), true);
  setLock(gui.getController("pitchButton"), true);
  setLock(gui.getController("playbackButton"), true);
  setLock(gui.getController("previousButton"), true);
  setLock(gui.getController("redoButton"), true);

  gui.addSlider("tempoSlider")
    .setLabel("Tempo")
      .setPosition(10, 80)
        .setSize(20, 200)
          .setRange(40, 280)
            .setValue(40)
              .setDecimalPrecision(0)
                .setColorForeground(color(0, 128, 0))
                  .setColorActive(color(0, 200, 0));

  gui.getController("tempoSlider").getCaptionLabel()
    .setPaddingX(5)
      .align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE)
        .setColor(color(0));
  gui.getController("tempoSlider").getValueLabel()
    .setPaddingX(0)
      .align(ControlP5.CENTER, -200)
        .setColor(color(255));

  gui.addSlider("volumeSlider")
    .setLabel("vol")
      .setPosition(10, 300)
        .setSize(20, 200)
          .setRange(0, 100)
            .setDecimalPrecision(0)
              .setValue(50);

  gui.getController("volumeSlider").getCaptionLabel()
    .align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE)
      .setPaddingX(0)
        .setColor(color(0));
  gui.getController("volumeSlider").getValueLabel()
    .setPaddingX(0)
      .align(ControlP5.CENTER, -200)
        .setColor(color(255));


  gui.addSlider("micLevel")
    .setLabel("mic")
      .setPosition(40, 300)
        .setSize(20, 200)
          .setRange(0, 100)
            ;

  gui.getController("micLevel").getCaptionLabel()
    .align(ControlP5.CENTER, ControlP5.BOTTOM_OUTSIDE)
      .setPaddingX(0)
        .setColor(color(0));
  gui.getController("micLevel").getValueLabel().setVisible(false);

  gui.getController("tempoSlider").setValue((int)library.getTempo());

  metro = gui.addCheckBox("metroBangFoo")
    .setPosition(SIDEBAR_WIDTH+(width-SIDEBAR_WIDTH)/2-250, height-110)
      .setSize(500, 100)
        .setItemsPerRow(1)
          .addItem("1", 0)
            .hide();

  metro.getItem(0).getCaptionLabel()
    .setFont(createFont("", 48))
      .setSize(48)
        .align(ControlP5.CENTER, ControlP5.CENTER)
          .setColor(255);
}

void setupFrame()
{
  frame.setTitle("Latido 0.9-alpha");
  if (frame != null) {
    frame.setResizable(true);
  }
  frame.addComponentListener(new ComponentAdapter() {
    public void componentResized(ComponentEvent e) {
      if (e.getSource()==frame) {
        //gui.getController("options").setPosition(width-230, 20);
        //gui.getController("websiteLink").setPosition(width-80, height-30);
        //println("resized to:" + width+" x "+height+" mouse: "+mouseY +" "+mouseY);
      }
    }
  }
  );
}

