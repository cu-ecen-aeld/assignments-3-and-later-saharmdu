CC = gcc
CFLAGS = -Wall

# Check if the CROSS_COMPILE variable is set
ifdef CROSS_COMPILE
    CC = $(CROSS_COMPILE)gcc
endif

# Name of the output binary
TARGET = writer

# Default target
all: $(TARGET)

# Linking the binary
$(TARGET): writer.o
	$(CC) $(CFLAGS) writer.o -o $(TARGET)

# Compiling the source file
writer.o: writer.c
	$(CC) $(CFLAGS) -c writer.c

# Clean target
clean:
	rm -f $(TARGET) *.o

.PHONY: all clean

