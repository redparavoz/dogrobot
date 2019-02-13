with Text_IO;
with Ada.Exceptions;

package body DEVS.SYSFS is

   ----------
   -- Init --
   ----------

   function Init
     (This : GPIO_Type;
      Forced : Boolean := False)
      return Boolean
   is
      Success : Boolean := False;
      Gpio_Str : constant String :=
        GPIO_Descriptor_Type'Image (TO_GPIO (This.Pin));
   begin
#if Private_Warnings then
      pragma Compile_Time_Warning (TRUE, "Implement devices initialization.");
#end if;
      -- Check if the pin is already assigned to another GPIO device to avoid
      -- function conflicts.
      if not Assigned_GPIO (TO_GPIO (This.Pin)) then

         case This.Class is
            when DIGITAL_OUT =>
               -- Handle device initialization
               if This.Export (Forced) and This.Set_Direction (GPIO_OUT) then
                  Text_IO.Put_Line
                    ("## "&Gpio_Str&" exported as "
                     &Class_Type'Image (This.Class)&" successfully.");
               end if;
            when DIGITAL_IN =>
               -- Handle device initialization
               if This.Export (Forced) and This.Set_Direction (GPIO_IN) then
                  Text_IO.Put_Line
                    ("## "&Gpio_Str&" exported as "
                     &Class_Type'Image (This.Class)&" successfully.");
               end if;

            when ANALOG_IN =>
               -- Handle device initialization
               null;

            when PWM =>
               -- Handle device initialization
               null;

         end case;

         Assigned_GPIO (TO_GPIO (This.Pin)) := True;

         return True;
      else
         return False;
      end if;

   exception
      when The_Error : others =>
         Text_IO.Put_Line("!!! "&Ada.Exceptions.Exception_Information (The_Error));
         return False;
   end Init;

   function DeInit
     (This : GPIO_Type)
     return Boolean
   is
   begin
      if Assigned_GPIO (TO_GPIO (This.Pin)) and This.Unexport then
         Assigned_GPIO (TO_GPIO (This.Pin)) := False;
         return True;
      end if;
      return False;

   exception
      when The_Error : others =>
         Text_IO.Put_Line("!!! "&Ada.Exceptions.Exception_Information (The_Error));
         return False;
   end DeInit;

   ------------
   -- Export --
   ------------

   function Export (This : GPIO_Type; Forced : Boolean) return Boolean is
      Full_Name : constant String := GPIO_BASE_PATH & "/export";
      Curr_File : Text_IO.File_Type;
      Cmd : constant String :=
        Format (GPIO_Number_Type'Image (TO_GPIO_NUMBER (TO_GPIO (This.Pin))));
   begin

      if Forced and then This.Unexport then null; end if;

      Text_IO.Put_Line ("## Exporting "&Full_Name&"["&Cmd&"]");
      Text_IO.Open (Curr_File, Text_IO.Out_File, Full_Name);
      Text_IO.Put_Line (Curr_File, Cmd);
      Text_IO.Close (Curr_File);
      Text_IO.Put_Line ("## Exportated "&Full_Name&"["&Cmd&"] successfully.");

      return True;

   exception
      when The_Error : others =>
         Text_IO.Put_Line("!!! "&Ada.Exceptions.Exception_Information (The_Error));
         return False;
   end Export;

   --------------
   -- Unexport --
   --------------

   function Unexport (This : GPIO_Type) return Boolean is
      Full_Name : constant String := GPIO_BASE_PATH & "/unexport";
      Curr_File : Text_IO.File_Type;
      Cmd : constant String :=
        Format (GPIO_Number_Type'Image (TO_GPIO_NUMBER (TO_GPIO (This.Pin))));
   begin
      Text_IO.Put_Line ("## Unexporting "&Full_Name&"["&Cmd&"]");
      Text_IO.Open (Curr_File, Text_IO.Out_File, Full_Name);
      Text_IO.Put_Line (Curr_File, Cmd);
      Text_IO.Close (Curr_File);
      Text_IO.Put_Line ("## Unexported "&Full_Name&"["&Cmd&"] successfully.");
      return True;
   exception
      when The_Error : others =>
         Text_IO.Put_Line("!!! "&Ada.Exceptions.Exception_Information (The_Error));
         return False;
   end Unexport;

   function Set_Direction (This : GPIO_Type; Direction : Direction_Type) return Boolean is
      Full_Name : constant String :=
        GPIO_BASE_PATH & "/gpio" &
        Format (GPIO_Number_Type'Image (TO_GPIO_NUMBER (TO_GPIO (This.Pin))))
        & "/direction";
      Curr_File : Text_IO.File_Type;
   begin
      Text_IO.Put_Line ("## Setting direction of "&Full_Name);
      Text_IO.Open (Curr_File, Text_IO.Out_File, Full_Name);
      case Direction is
         when GPIO_IN  => Text_IO.Put (Curr_File, "in");
         when GPIO_OUT => Text_IO.Put (Curr_File, "out");
      end case;
      Text_IO.Close (Curr_File);
      Text_IO.Put_Line ("## Direction of "&Full_Name&" is set successfully.");

      return True;
   exception
      when The_Error : others =>
         Text_IO.Put_Line("!!! "&Ada.Exceptions.Exception_Information (The_Error));
         return False;
   end Set_Direction;

   function Set_Value (This : GPIO_Type; Value : Integer) return Boolean is
      Full_Name : constant String :=
        GPIO_BASE_PATH & "/gpio" &
        Format (GPIO_Number_Type'Image (TO_GPIO_NUMBER (TO_GPIO (This.Pin))))
        & "/value";
      Curr_File : Text_IO.File_Type;
   begin
      if Assigned_GPIO (TO_GPIO (This.Pin)) then
         Text_IO.Put_Line ("## Setting value of "&Full_Name);
         Text_IO.Open (Curr_File, Text_IO.Out_File, Full_Name);
         Text_IO.Put_Line (Curr_File, Format (Integer'Image (Value)));
         Text_IO.Close (Curr_File);
         Text_IO.Put_Line ("## Value of "&Full_Name&" is set successfully.");
         return True;
      else
         Text_IO.Put_Line ("Gpio value set error.");
         return False;
      end if;

   exception
      when The_Error : others =>
         Text_IO.Put_Line("!!! "&Ada.Exceptions.Exception_Information (The_Error));
         return False;
   end Set_Value;

   function Get_Value (This : GPIO_Type) return Integer is
      Full_Name : constant String :=
        GPIO_BASE_PATH & "/gpio" &
        Format (GPIO_Number_Type'Image (TO_GPIO_NUMBER (TO_GPIO (This.Pin))))
        & "/value";
      Curr_File : Text_IO.File_Type;
      Value : Integer := 0;
   begin
      if Assigned_GPIO (TO_GPIO (This.Pin)) then
         Text_IO.Open (Curr_File, Text_IO.In_File, Full_Name);
         Value := Integer'Value (Text_IO.Get_Line (Curr_File));
         Text_IO.Close (Curr_File);
      else
         Text_IO.Put_Line ("Gpio value get error.");
      end if;

      return Value;

   exception
      when The_Error : others =>
         Text_IO.Put_Line("!!! "&Ada.Exceptions.Exception_Information (The_Error));
         return 0;
   end Get_Value;

   procedure Init_Devices
     (Forced : Boolean := False) is
   begin

      if not Dev_Lamp0.Init or
        not Dev_Lamp1.Init or
        not Dev_Lamp2.Init or
        not Dev_Motor0.Init or
        not Dev_CheckFlag0.Init or
        not Dev_CheckFlag1.Init or
        not Dev_Analog0.Init or
        not Dev_Analog1.Init or
        not Dev_Lamp0.Init
      then
         Text_IO.Put_Line
           ("There was an error while initializing the devices.");
      else
         Text_IO.Put_Line ("## Devices initialized successfully.");
      end if;

   end Init_Devices;

   procedure DeInit_Devices is
   begin
      if Dev_Lamp0.DeInit and
        Dev_Lamp1.DeInit and
        Dev_Lamp2.DeInit and
        Dev_Motor0.DeInit and
        Dev_CheckFlag0.DeInit and
        Dev_CheckFlag1.DeInit and
        Dev_Analog0.DeInit and
        Dev_Analog1.DeInit and
        Dev_Lamp0.DeInit
      then
         Text_IO.Put_Line ("## All devices uninitialized successfully.");
      end if;
   end DeInit_Devices;

   procedure Test_File_Handling is
      File_In : Text_IO.File_Type;
      File_Path : String := "/home/pi/test_file";
   begin
      Text_IO.Put_Line ("File will open.");
      Text_IO.Open (File => File_In,
                    Mode => Text_IO.Out_File,
                    Name => File_Path);
      Text_IO.Put_Line ("File will be written.");
      Text_IO.Put (File_In, "5");
      Text_IO.Put_Line (File_Path & "is written.");
      Text_IO.Close (File_In);
      Text_IO.Put_Line (File_Path & "is closed.");
   end Test_File_Handling;

end DEVS.SYSFS;
