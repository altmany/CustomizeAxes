# CustomizeAxes
Live task to customize Matlab axes interactively 

## Setup/usage as a live task
1. Download the CustomizeAxes files to your computer
2. Add the CustomizeAxes folder path to Matlab using the `addpath` function or the "Set Path" button in the Matlab Desktop toolstrip. If you use `addpath`, you need to ensure to run it in every Matlab session, otherwise the live task will not be accessible in the Editor. 
3. Run `matlab.task.configureMetadata([folder '/CustomizeAxes'])` in Matlab (replace `folder` with the CustomizeAxes path above)
4. In the Matlab Editor, start a New Live Script, click the "Task" dropdown in the toolstrip, and ensure that you see the CustomizeAxes task:
![image](https://user-images.githubusercontent.com/10243182/200378631-f49977eb-3e8a-47fc-8588-a734954518df.png)
5. Insert the live task into your live Matlab script by clicking the live task button. Here is a usage example:
![image](https://github.com/altmany/CustomizeAxes/blob/main/CustomizeAxes%20Live%20task.png?raw=true)

## Running as a standalone dialog window
CustomizeAxes can also run as a standalong window, using the syntax `CustomizeAxes(haxes)`, where hAxes is the requested axes handle. 
You can also run `CustomizeAxes()` without an axes handle, allowing you to interactively select the requested axes.
![image](https://github.com/altmany/CustomizeAxes/blob/main/CustomizeAxes%20dialog%20window.png?raw=true)
