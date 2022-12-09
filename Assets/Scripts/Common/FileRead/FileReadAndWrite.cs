
using System.Collections.Generic;
using System.IO;
using UnityEngine;


namespace Common
{
    public static class FileReadAndWrite
    {

        public static string DirectReadFile(string path)
        {
            if (File.Exists(path))
            {
                return File.ReadAllText(path);
            }
            File.Create(path).Dispose();
            return null;
        }

        public static void WriteFile(string path, string content)
        {
            if (File.Exists(path))
            {
                File.WriteAllText(path, content);
                return;
            }
            File.Create(path).Dispose();
            File.WriteAllText(path, content);
        }

        /// <summary>
        /// 读取文件内容，使用尖括号将所有内容区分开来
        /// 注意的是要求所有的内容都存在一个个尖括号中，返回值也是返回所有尖括号中的内容
        /// </summary>
        /// <param name="path">路径</param>
        /// <returns>每一个尖括号的内容</returns>
        public static List<string> ReadFileByAngleBrackets(string path)
        {
            if (File.Exists(path))
            {
                string temp = File.ReadAllText(path);
                if(temp != null && !temp.Equals(""))
                {
                    List<string> list = new List<string>();
                    for(int i=temp.IndexOf('<'); i<temp.Length && i != -1;)
                    {
                        //获得这个的所有数据
                        int next = temp.IndexOf('>', i);
                        //获得括号中存储的信息
                        if((i+1) >=(next - 1))
                        {
                            i = temp.IndexOf('<', next);
                            list.Add("");
                            continue;
                        }
                        string str = temp.Substring(i + 1, next - 1 - i);
                        list.Add(str);
                        i = temp.IndexOf('<', next);
                    }
                    return list;
                }
                return null;
            }
            else
            {
                Debug.Log(path + " 路径不存在");
            }
            return null;
        }
    }
}