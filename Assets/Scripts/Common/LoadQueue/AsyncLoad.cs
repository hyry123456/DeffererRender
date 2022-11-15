using System;
using System.Collections.Generic;
using System.Threading;
using UnityEngine;

/// <summary>
/// 多线程加载类，用来进行大文件读取之类的
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
                //这个会导致一开始就关闭该对象，所以不设置该属性
                //gameObject.hideFlags = HideFlags.HideAndDontSave;
                DontDestroyOnLoad(gameObject);      //保证不会在场景中被删除
            }
            return instance; 
        }
    }

    /// <summary>    /// 等待栈，用来将所有需要处理的委托存储到该位置，这里是等待区    /// </summary>
    private static List<Action> commands = new List<Action>();
    /// <summary>    /// 处理栈，在子线程中读取该列表数据，然后逐个处理    /// </summary>
    private List<Action> localCommands = new List<Action> ();
    /// <summary>  /// C#提供的多线程控制，由于我们只需要一个线程，因此需要使用这个类进行控制  /// </summary>
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

            lock (commands)     //线程锁，防止异步导致插入出错
            {
                //将待处理栈中的全部数据加入到处理栈中
                localCommands.AddRange(commands);
                commands.Clear();
            }
            //处理所有数据，是直接执行完全部函数，当数组中的所有函数执行完后会进行清空
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
        if (localCommands.Contains(action)) //如果已经在栈中，就退出
            return;

        lock (commands)
        {
            if(!commands.Contains(action))  //只有不在运行栈也不在等待栈时才可以加入等待栈
                commands.Add(action);   //加入到待加载栈中，而不是执行栈中
        }
    }


    private void OnDisable()
    {
        isRunning = false;
    }
}
