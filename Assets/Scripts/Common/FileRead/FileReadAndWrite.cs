
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
        /// ��ȡ�ļ����ݣ�ʹ�ü����Ž������������ֿ���
        /// ע�����Ҫ�����е����ݶ�����һ�����������У�����ֵҲ�Ƿ������м������е�����
        /// </summary>
        /// <param name="path">·��</param>
        /// <returns>ÿһ�������ŵ�����</returns>
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
                        //����������������
                        int next = temp.IndexOf('>', i);
                        //��������д洢����Ϣ
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
                Debug.Log(path + " ·��������");
            }
            return null;
        }
    }
}