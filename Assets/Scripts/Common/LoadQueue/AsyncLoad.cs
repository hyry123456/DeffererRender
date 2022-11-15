using System;
using System.Collections.Generic;
using System.Threading;
using UnityEngine;

/// <summary>
/// ���̼߳����࣬�������д��ļ���ȡ֮���
/// </summary>
public class AsyncLoad : MonoBehaviour
{
    private static AsyncLoad instance;
    public static AsyncLoad Instance
    {
        get 
        {
            if(instance == null)
            {
                GameObject gameObject = new GameObject("AsyncLoad");
                gameObject.AddComponent<AsyncLoad>();
                //����ᵼ��һ��ʼ�͹رոö������Բ����ø�����
                //gameObject.hideFlags = HideFlags.HideAndDontSave;
                DontDestroyOnLoad(gameObject);      //��֤�����ڳ����б�ɾ��
            }
            return instance; 
        }
    }

    /// <summary>    /// �ȴ�ջ��������������Ҫ�����ί�д洢����λ�ã������ǵȴ���    /// </summary>
    private static List<Action> commands = new List<Action>();
    /// <summary>    /// ����ջ�������߳��ж�ȡ���б����ݣ�Ȼ���������    /// </summary>
    private List<Action> localCommands = new List<Action> ();
    /// <summary>  /// C#�ṩ�Ķ��߳̿��ƣ���������ֻ��Ҫһ���̣߳������Ҫʹ���������п���  /// </summary>
    private AutoResetEvent resetEvent;
    private Thread thread;
    private bool isRunning;

    public bool IsRunning
    {
        get { return isRunning; }
    }

    private void Awake()
    {
        if(instance != null)
        {

            Destroy(gameObject);
            return;
        }
        instance = this;
        isRunning = true;
        resetEvent = new AutoResetEvent(false);
        thread = new Thread(Run);
        thread.Start();

    }

    public void Run()
    {

        while (isRunning)
        {
            resetEvent.WaitOne();

            lock (commands)     //�߳�������ֹ�첽���²������
            {
                //��������ջ�е�ȫ�����ݼ��뵽����ջ��
                localCommands.AddRange(commands);
                commands.Clear();
            }
            //�����������ݣ���ֱ��ִ����ȫ���������������е����к���ִ������������
            foreach(var i in localCommands)
            {
                i();
            }
            localCommands.Clear();
        }
    }

    public void AddAction(Action action)
    {
        resetEvent.Set();
        if (localCommands.Contains(action)) //����Ѿ���ջ�У����˳�
            return;

        lock (commands)
        {
            if(!commands.Contains(action))  //ֻ�в�������ջҲ���ڵȴ�ջʱ�ſ��Լ���ȴ�ջ
                commands.Add(action);   //���뵽������ջ�У�������ִ��ջ��
        }
    }


    private void OnDisable()
    {
        isRunning = false;
    }
}
