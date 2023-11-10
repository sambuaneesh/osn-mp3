import matplotlib.pyplot as plt

# Specify the path to your data file
data_file_path = 'data'

# Read data from the file
with open(data_file_path, 'r') as file:
    data = file.read().strip()

# Split the data into lines and extract pid and ticks
lines = data.split('\n')
pid_ticks = [list(map(int, line.split())) for line in lines]

# Separate pid and ticks for plotting
pids, ticks = zip(*pid_ticks)

# Create scatter plot
plt.scatter(ticks, pids, marker='o', color='blue')
plt.xlabel('Ticks')
plt.ylabel('Process PID')
plt.title('Scatter Plot of Process PID with Ticks')
plt.grid(True)
plt.show()
