    properties (Access = private)
        rngSeed               double  % 随机种子
        isPaused              logical % 是否暂停
        isStopped             logical % 是否停止
        plotFullCurve         logical = false % 是否显示完整图像
        keepPlot              logical = false % 保持图像
    end

    methods (Access = private)

        function nakagamiChan =nakagami_channel(~,m, omega, num_samples, sampleRate, dopplerShift)

            % 生成 Nakagami 分布的随机变量
            nakagamiGains = sqrt(gamrnd(m, omega / m, num_samples, 1));

            % 生成时间向量
            t = (0:num_samples-1) / sampleRate;

            % 加入多普勒频移
            dopplerEffect = exp(1i * 2 * pi * dopplerShift * t);

            % 将多普勒效应应用到 Nakagami 信道增益
            nakagamiChan = nakagamiGains .* dopplerEffect.';

            % 归一化增益
            nakagamiChan = nakagamiChan / sqrt(mean(abs(nakagamiChan).^2));
        end

        % 计算误码率函数
        function ber = calculate_ber(~, originalBits, demodBits)
            % 确保两个比特流长度一致
            minLen = min(length(originalBits), length(demodBits));
            originalBits = originalBits(1:minLen);
            demodBits = demodBits(1:minLen);

            [numErrors, ~] = biterr(originalBits, demodBits);
            ber = numErrors / minLen;
        end
        function demodData = demodulateSignal(~, noisySignal, modulationType)
            % 根据选择的调制方式进行解调
            switch modulationType
                case 'QPSK调制'
                    demodData = pskdemod(noisySignal, 4, pi/4, 'gray', 'OutputType', 'bit');
                case '16QAM调制'
                    demodData = qamdemod(noisySignal, 16, 'OutputType', 'bit');
                case 'BPSK调制'
                    demodData = pskdemod(noisySignal, 2);
                otherwise
                    error('无效的调制方式');
            end
        end

        function noisySignal = addNoiseWithPathLoss(~,signal, snr, pathLossExponent, shadowFading,pathDistance)
            % 计算信号功率
            signalPower = mean(abs(signal).^2);

            if pathDistance ~= 0 || shadowFading ~= 0
                % 对数距离路径损耗计算
                d0 = 1; % 参考距离，通常为 1 米
                pathDistance = max(pathDistance, d0); % 确保 pathDistance 不小于 d0
                pathLoss = 10 * pathLossExponent * log10(pathDistance / d0);

                % 计算总损耗
                totalLoss = pathLoss + shadowFading * randn;

                fprintf('Path Loss: %.2f dB\n', pathLoss);
                fprintf('Shadow Fading: %.2f dB\n', shadowFading * randn);
                fprintf('Total Loss: %.2f dB\n', totalLoss);
                fprintf('Path Loss Exponent: %.2f\n', pathLossExponent);
                % 应用路径损耗和阴影衰落
                signalWithLoss = signal .* 10.^(-totalLoss/20);

                % 计算噪声功率
                noisePower = signalPower / (10^(snr / 10));

                % 添加噪声
                noisySignal = signalWithLoss + sqrt(noisePower/2) * (randn(size(signal)) + 1i * randn(size(signal)));
            else
                % 使用awgn函数添加噪声
                noisySignal = awgn(signal, snr, 'measured');
            end
        end
    end