namespace Viewer
{
    partial class Form1
    {
        /// <summary>
        /// Variable nécessaire au concepteur.
        /// </summary>
        private System.ComponentModel.IContainer components = null;

        /// <summary>
        /// Nettoyage des ressources utilisées.
        /// </summary>
        /// <param name="disposing">true si les ressources managées doivent être supprimées ; sinon, false.</param>
        protected override void Dispose(bool disposing)
        {
            if (disposing && (components != null))
            {
                components.Dispose();
            }
            base.Dispose(disposing);
        }

        #region Code généré par le Concepteur Windows Form

        /// <summary>
        /// Méthode requise pour la prise en charge du concepteur - ne modifiez pas
        /// le contenu de cette méthode avec l'éditeur de code.
        /// </summary>
        private void InitializeComponent()
        {
            this.button1 = new System.Windows.Forms.Button();
            this.openFileDialog1 = new System.Windows.Forms.OpenFileDialog();
            this.pVisual = new System.Windows.Forms.GroupBox();
            this.tbMinW = new System.Windows.Forms.TextBox();
            this.tbMaxW = new System.Windows.Forms.TextBox();
            this.label1 = new System.Windows.Forms.Label();
            this.label2 = new System.Windows.Forms.Label();
            this.tbMinRO = new System.Windows.Forms.TextBox();
            this.tbMaxRO = new System.Windows.Forms.TextBox();
            this.button2 = new System.Windows.Forms.Button();
            this.SuspendLayout();
            // 
            // button1
            // 
            this.button1.Location = new System.Drawing.Point(16, 9);
            this.button1.Name = "button1";
            this.button1.Size = new System.Drawing.Size(27, 26);
            this.button1.TabIndex = 0;
            this.button1.Text = "...";
            this.button1.UseVisualStyleBackColor = true;
            this.button1.Click += new System.EventHandler(this.button1_Click);
            // 
            // openFileDialog1
            // 
            this.openFileDialog1.FileName = "openFileDialog1";
            // 
            // pVisual
            // 
            this.pVisual.Location = new System.Drawing.Point(16, 80);
            this.pVisual.Name = "pVisual";
            this.pVisual.Size = new System.Drawing.Size(828, 533);
            this.pVisual.TabIndex = 1;
            this.pVisual.TabStop = false;
            this.pVisual.Text = "Execution";
            // 
            // tbMinW
            // 
            this.tbMinW.Location = new System.Drawing.Point(157, 54);
            this.tbMinW.Name = "tbMinW";
            this.tbMinW.Size = new System.Drawing.Size(100, 20);
            this.tbMinW.TabIndex = 2;
            // 
            // tbMaxW
            // 
            this.tbMaxW.Location = new System.Drawing.Point(286, 54);
            this.tbMaxW.Name = "tbMaxW";
            this.tbMaxW.Size = new System.Drawing.Size(100, 20);
            this.tbMaxW.TabIndex = 3;
            // 
            // label1
            // 
            this.label1.AutoSize = true;
            this.label1.Location = new System.Drawing.Point(154, 9);
            this.label1.Name = "label1";
            this.label1.Size = new System.Drawing.Size(55, 13);
            this.label1.TabIndex = 4;
            this.label1.Text = "Min Offset";
            // 
            // label2
            // 
            this.label2.AutoSize = true;
            this.label2.Location = new System.Drawing.Point(283, 9);
            this.label2.Name = "label2";
            this.label2.Size = new System.Drawing.Size(58, 13);
            this.label2.TabIndex = 5;
            this.label2.Text = "Max Offset";
            // 
            // tbMinRO
            // 
            this.tbMinRO.Location = new System.Drawing.Point(157, 25);
            this.tbMinRO.Name = "tbMinRO";
            this.tbMinRO.Size = new System.Drawing.Size(100, 20);
            this.tbMinRO.TabIndex = 6;
            // 
            // tbMaxRO
            // 
            this.tbMaxRO.Location = new System.Drawing.Point(286, 28);
            this.tbMaxRO.Name = "tbMaxRO";
            this.tbMaxRO.Size = new System.Drawing.Size(100, 20);
            this.tbMaxRO.TabIndex = 7;
            // 
            // button2
            // 
            this.button2.Location = new System.Drawing.Point(59, 12);
            this.button2.Name = "button2";
            this.button2.Size = new System.Drawing.Size(75, 23);
            this.button2.TabIndex = 8;
            this.button2.Text = "refresh";
            this.button2.UseVisualStyleBackColor = true;
            this.button2.Click += new System.EventHandler(this.button2_Click);
            // 
            // Form1
            // 
            this.AutoScaleDimensions = new System.Drawing.SizeF(6F, 13F);
            this.AutoScaleMode = System.Windows.Forms.AutoScaleMode.Font;
            this.ClientSize = new System.Drawing.Size(857, 625);
            this.Controls.Add(this.button2);
            this.Controls.Add(this.tbMaxRO);
            this.Controls.Add(this.tbMinRO);
            this.Controls.Add(this.label2);
            this.Controls.Add(this.label1);
            this.Controls.Add(this.tbMaxW);
            this.Controls.Add(this.tbMinW);
            this.Controls.Add(this.pVisual);
            this.Controls.Add(this.button1);
            this.Name = "Form1";
            this.Text = "Form1";
            this.ResumeLayout(false);
            this.PerformLayout();

        }

        #endregion

        private System.Windows.Forms.Button button1;
        private System.Windows.Forms.OpenFileDialog openFileDialog1;
        private System.Windows.Forms.GroupBox pVisual;
        private System.Windows.Forms.TextBox tbMinW;
        private System.Windows.Forms.TextBox tbMaxW;
        private System.Windows.Forms.Label label1;
        private System.Windows.Forms.Label label2;
        private System.Windows.Forms.TextBox tbMinRO;
        private System.Windows.Forms.TextBox tbMaxRO;
        private System.Windows.Forms.Button button2;
    }
}

