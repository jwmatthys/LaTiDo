class MelodyLibrary
{
  String[] lines;
  String indexPath, midiPath, imagePath, rhythmPath, textPath;
  String midiExt, imageExt; // file extensions contained in second line of latido.txt
  String filename;
  int tempo;
  float countin;
  int currentLine;
  boolean rhythm;
  final int lineOffset = 3;

  MelodyLibrary ()
  {
  }

  String load (String path)
  {
    indexPath = path+"/latido.txt";
    midiPath = dataPath(path)+"/midi/";
    imagePath = path+"/image/";
    rhythmPath = dataPath(path)+"/rhythm/";
    textPath = path+"/text/";
    lines = loadStrings(indexPath);
    if (lines==null) return "";
    String[] extensions = split(lines[1], ' ');
    imageExt = extensions[0];
    midiExt = extensions[1];
    currentLine = 0;
    parse (0);
    return lines[0];
  }

  void parse (int line)
  {
    String[] current = split(lines[line+lineOffset], ' ');
    filename = current[0];
    tempo = int(current[1]);
    countin = float(current[2]);
    if (current.length>3) rhythm = true;
  }

  void loadNext()
  {
    currentLine++;
    if (currentLine >= lines.length - lineOffset) currentLine--;
    parse(currentLine);
  }

  void loadPrevious()
  {
    currentLine--;
    if (currentLine < 0) currentLine++;
    parse(currentLine);
  }

  String getMidi ()
  {
    return midiPath+filename+"."+midiExt;
  }

  String getImage ()
  {
    return imagePath+filename+"."+imageExt;
  }

  String getRhythm ()
  {
    return rhythmPath+filename+".txt";
  }

  String getText ()
  {
    return textPath+filename+".txt";
  }

String getName ()
  {
    return filename;
  }
  int getTempo ()
  {
    return tempo;
  }

  float getCountin ()
  {
    return countin;
  }
}