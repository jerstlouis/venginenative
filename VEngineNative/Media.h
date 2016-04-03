#pragma once

class Media
{
public:
    static void loadFileMap(string path);
    static string readString(string key);
    static string getPath(string key);
    static int Media::readBinary(string key, char** out_bytes);

private:

    static map<string, string> mediaMap;
    static void searchRecursive(string path);

};

